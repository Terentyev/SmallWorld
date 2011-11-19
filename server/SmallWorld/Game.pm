package SmallWorld::Game;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );
use List::Util qw( min );

use SmallWorld::Consts;
use SmallWorld::DB;
use SmallWorld::Player;
use SmallWorld::Races;
use SmallWorld::Region;
use SmallWorld::SpecialPowers;

# принимает параметры:
#   db  -- объект класса SmallWorld::DB
#   sid -- session id игрока, с которым сейчас работаем
sub new {
  my $class = shift;
  my $self = { gameState => undef, db => shift };

  bless $self, $class;

  $self->load(@_);

  return $self;
}

sub mergeGameState {
  my ($self, $gs) = @_;
  grep { $self->{gameState}->{$_} = $gs->{$_} } keys %$gs;
}

# загружает информацию об игре из БД
sub load {
  my ($self, $sid, $act) = @_;
  my $game = $self->{db}->getGameState($sid);
  my $map = $self->{db}->getMap($game->{MAPID});

  $self->{_version} = $game->{VERSION};
  $self->{gameState} = {
    gameInfo       => {
      gameId            => $game->{ID},
      gameName          => $game->{NAME},
      gameDescription   => $game->{DESCRIPTION},
      currentPlayersNum => $self->{db}->playersCount($game->{ID}),
    },
    map            => {
      mapId      => $game->{MAPID},
      mapName    => $map->{NAME},
      turnsNum   => $map->{TURNSNUM},
      playersNum => $map->{PLAYERSNUM},
    },
  };
  if ( !defined $game->{STATE} ) {
    $self->init($game, $map);
  }
  else {
    $self->mergeGameState(decode_json($game->{STATE}));
  }
}

sub init {
  my ($self, $game, $map) = @_;

  # заполняем регионы
  my $regions = decode_json($map->{REGIONS});
  my $i = 0;
  $self->{gameState}->{regions} = [
    map { {
      regionId         => ++$i,
      constRegionState => $_->{landDescription},
      adjacentRegions  => $_->{adjacent},

      ownerId          => undef,                # идентификатор игрока-владельца
      tokenBadgeId     => undef,                # идентификатор расы игрока-владельца
      tokensNum        => 1 * $_->{population}, # количество фигурок
      conquestIdx      => undef,                # порядковый номер завоевания (обнуляется по окончанию хода)
      holeInTheGround  => undef,                # 1 если присутствует нора полуросликов
      lair             => undef,                # кол-во пещер троллей
      encampment       => undef,                # кол-во лагерей (какая осень в лагерях...)
      dragon           => undef,                # 1 если присутствует дракон
      fortiefied       => undef,                # кол-во фортов
      hero             => undef,                # 1 если присутствует герой
      inDecline        => undef                 # 1 если раса tokenBadgeId в упадке
   } } @{$regions}
  ];

  # загружаем игроков
  my $players = $self->{db}->getPlayers($game->{ID});
  $i = 0;
  $self->{gameState}->{players} = [
    map { {
      playerId           => $_->{ID},
      username           => $_->{USERNAME},
      isReady            => 1 * $_->{ISREADY},
      coins              => INITIAL_COINS_NUM,
      tokensInHand       => INITIAL_TOKENS_NUM,
      priority           => $i++,
#      dice               => undef,              # число, которое выпало при броске костей берсерка
      currentTokenBadge  => {
        tokenBadgeId     => undef,
        totalTokensNum   => undef,
        raceName         => undef,
        specialPowerName => undef
      },
      declinedTokenBadge => undef
    } } @{$players}
  ];

  $self->mergeGameState({
    activePlayerId => $self->{gameState}->{players}->[0]->{playerId},
    conquerorId    => undef,
    state          => GS_SELECT_RACE,
    currentTurn    => 0,
    tokenBadges    => $self->initTokenBadges(),
    storage        => $self->initStorage(),
  });
}

# начальное состояние пар раса/умение
sub initTokenBadges {
  my $self = shift;
  my @sp = @{ &SPECIAL_POWERS };
  my @races = @{ &RACES };
  my @result = ();

  my $j = 0;
  while ( @sp ) {
    push @result, {
      tokenBadgeId     => $j++,
      specialPowerName => splice(@sp, rand(scalar(@sp)), 1),
    };
  }

  $j = 0;
  while ( @races ) {
    $result[$j++]->{raceName} = splice(@races, rand(scalar(@races)), 1);
  }

  return \@result;
}

# начальное состояние хранилища фигурок и карточек
sub initStorage {
  return {
    &RACE_SORCERERS => SORCERERS_TOKENS_MAX,
  };
}

# сохраняет состояние игры в БД
sub save {
  my $self = shift;
  my $gs = $self->{gameState};
  # вместо того, чтобы сохранять в json объекты-игроков, сохраняем только
  # информацию о них
  grep { $_ = { %$_ } if UNIVERSAL::can($_, 'can') } @{ $gs->{players} };
  grep { $_ = { %$_ } if UNIVERSAL::can($_, 'can') } @{ $gs->{regions} };
  $self->{db}->saveGameState(encode_json($gs), $gs->{gameInfo}->{gameId});
  $self->{_version}++;
}

# устанавливает определенные карточки рас и умений
sub setTokenBadge {
  my ($self, $name, $tokens) = @_;
  return if !defined $tokens;
  my $myTokens = $self->{gameState}->{tokenBadges};
  for ( my $i = 0; $i < scalar(@{ $tokens }); ++$i ) {
    foreach ( @{ $myTokens } ) {
      if ( defined $_->{$name} && $_->{$name} eq $tokens->[$i] ) {
        $_->{$name} = $myTokens->[$i]->{$name};
        $myTokens->[$i]->{$name} = $tokens->[$i];
        last;
      }
    }
  }
}

# возвращает состояние игры для конкретного игрока (удаляет секретные данные)
sub getGameStateForPlayer {
  my $self = shift;
  my $playerId = $self->{db}->getPlayerId(shift);
  my $gs = \%{ $self->{gameState} };
  $gs->{visibleTokenBadges} = [ @{ $gs->{tokenBadges} }[0..5] ];
  my $result = {
    gameId             => $gs->{gameInfo}->{gameId},
    gameName           => $gs->{gameInfo}->{gameName},
    gameDescription    => $gs->{gameInfo}->{gameDescription},
    currentPlayersNum  => $gs->{gameInfo}->{currentPlayersNum},
    activePlayerId     => $gs->{activePlayerId},
    state              => $gs->{state},
    currentTurn        => $gs->{currentTurn},
    map                => \%{ $gs->{map} },
    visibleTokenBadges => $gs->{visibleTokenBadges}
  };
  $result->{map}->{regions} = [];
  grep {
    push @{ $result->{map}->{regions} }, {
#regionId           => $_->{regionId},
      constRegionState   => \@{ $_->{constRegionState} },
      adjacentRegions    => \@{ $_->{adjacentRegions} },
      currentRegionState => {
        ownerId         => $_->{ownerId},
        tokenBadgeId    => $_->{tokenBadgeId},
        tokensNum       => $_->{tokensNum},
        holeInTheGround => $_->{holeInTheGround},
        lair            => $_->{lair},
        encampment      => $_->{encampment},
        dragon          => $_->{dragon},
        fortified       => $_->{fortified},
        hero            => $_->{hero},
        inDecline       => $_->{inDecline}
      }
    }
  } @{ $gs->{regions} };
  $result->{players} = undef;
  grep {
    push @{ $result->{players} }, {
      userId => $_->{playerId},
      username => $_->{username},
      isReady  => $_->{isReady},
      coins    => $_->{coins},
      tokensInHand => $_->{tokensInHand},
      priority     => $_->{priority},
      currentTokenBadge => \%{ $_->{currentTokenBadge} },
      declineTokenBadge => \%{ $_->{declineTokenBadge} }
    }
  } @{ $gs->{players} };
  grep {delete $_->{coins} if $_->{userId} != $playerId} @{ $result->{players} };
  $self->removeNull($result);
  return $result;
}

# удаляет из хеша _все_ ключи, значения которых неопределены
sub removeNull {
  my ($self, $o) = @_;
  if ( ref $o eq 'HASH' ) {
    foreach ( keys %{ $o } ) {
      if ( defined $o->{$_} ) {
        $self->removeNull($o->{$_});
      }
      else {
        delete $o->{$_};
      }
    }
  }
  elsif ( ref $o eq 'ARRAY' ) {
    grep { $self->removeNull($_) } @{ $o };
  }
}

# возвращает кол-во регионов в игре
sub regionsNum {
  return $@{ $_[0]->{gameState}->{regions} };
}

# возвращает игрока из массива игроков по id или sid
sub getPlayer {
  my ($self, $param) = @_;
  my $id = defined $param ? $param->{id} : undef;
  if ( defined $param && defined $param->{sid} ) {
    $id = $self->{db}->getPlayerId($param->{sid});
  }
  elsif ( !defined $id ) {
    $id = $self->{gameState}->{activePlayerId};
  }

  # находим в массиве игроков текущего игрока
  foreach ( @{ $self->{gameState}->{players} } ) {
    if ( $_->{playerId} == $id ) {
      # если объект-игрока уже создан, то возвращаем его
      return $_ if UNIVERSAL::can($_, 'can');
      # иначе создаем новый экземпляр
      return SmallWorld::Player->new($_);
    }
  }
}

# возвращает регион из массива регионов по id
sub getRegion {
  my ($self, $id) = @_;
  foreach ( @{ $self->{gameState}->{regions} } ) {
    if ( $_->{regionId} == $id ) {
      # если объект-регион уже создан, то возвращаем его
      return $_ if UNIVERSAL::can($_, 'can');
      # иначе создаем новый экземпляр
      return SmallWorld::Region->new($_);
    }
  }
}

# возвращает объект класса, который соответсвует расе
sub createRace {
  my ($self, $badge) = @_;
  my $race = 'SmallWorld::BaseRace';
  
  if ( defined $badge && defined $badge->{raceName} ) {
    $race = {
      &RACE_AMAZONS   => 'SmallWorld::RaceAmazons',
      &RACE_DWARVES   => 'SmallWorld::RaceDwarves',
      &RACE_ELVES     => 'SmallWorld::RaceElves',
      &RACE_GIANTS    => 'SmallWorld::RaceGiants',
      &RACE_HALFLINGS => 'SmallWorld::RaceHalflings',
      &RACE_HUMANS    => 'SmallWorld::RaceHumans',
      &RACE_ORCS      => 'SmallWorld::RaceOrcs',
      &RACE_RATMEN    => 'SmallWorld::RaceRatmen',
      &RACE_SKELETONS => 'SmallWorld::RaceSkeletons',
      &RACE_SORCERERS => 'SmallWorld::RaceSorcerers',
      &RACE_TRITONS   => 'SmallWorld::RaceTritons',
      &RACE_TROLLS    => 'SmallWorld::RaceTrolls',
      &RACE_WIZARDS   => 'SmallWorld::RaceWizards'
    }->{ $badge->{raceName} };
  }
  return $race->new($self->{gameState}->{regions}, $badge);
}

# возвращает объект класса, который соответствует способности
sub createSpecialPower {
  my ($self, $badge, $player) = @_;
  my $power = 'SmallWorld::BaseSp';
  if ( defined $badge && defined ($badge = $player->{$badge}) && defined $badge->{specialPowerName} ) {
    $power = {
      &SP_ALCHEMIST     => 'SmallWorld::SpAlchemist',
      &SP_BERSERK       => 'SmallWorld::SpBerserk',
      &SP_BIVOUACKING   => 'SmallWorld::SpBivouacking',
      &SP_COMMANDO      => 'SmallWorld::SpCommado',
      &SP_DIPLOMAT      => 'SmallWorld::SpDiplomat',
      &SP_DRAGON_MASTER => 'SmallWorld::SpDragonMaster',
      &SP_FLYING        => 'SmallWorld::SpFlying',
      &SP_FOREST        => 'SmallWorld::SpForest',
      &SP_FORTIFIED     => 'SmallWorld::SpFortified',
      &SP_HEROIC        => 'SmallWorld::SpHeroic',
      &SP_HILL          => 'SmallWorld::SpHill',
      &SP_MERCHANT      => 'SmallWorld::SpMerchant',
      &SP_PILLAGING     => 'SmallWorld::SpPillaging',
      &SP_SEAFARING     => 'SmallWorld::SpSeafaring',
      &SP_STOUT         => 'SmallWorld::SpStout',
      &SP_SWAMP         => 'SmallWorld::SpSwamp',
      &SP_UNDERWORLD    => 'SmallWorld::SpUnderworld',
      &SP_WEALTHY       => 'SmallWorld::SpWealthy'
    }->{ $badge->{specialPowerName} };
  }
  return $power->new($player, $self->{gameState}->{regions}, $badge);
}

# возвращает первое ли это нападение (есть ли на карте регионы с этой расой)
sub isFirstConquer {
  my ($self) = @_;
  my $player = $self->getPlayer();
  return !(grep {
    $player->activeConq($_)
  } @{ $_[0]->{gameState}->{regions} });
}

# возвращает есть ли у региона иммунитет к нападению
sub isImmuneRegion {
  my $region = $_[1];
  return grep {
    $region->{$_}
  } qw( holeInTheGround dragon hero );
}

# возвращает следующий порядковый номер завоевания регионов
sub nextConquestIdx {
  my $result = -1;
  grep { $result = max( $result, $_->conquestIdx ) } @{ $_[0]->{regions} };
  return $result + 1;
}

# бросаем кубик (возвращает число от 1 до 6)
sub random {
  return int(rand(5)) + 1;
}

# возвращает количество фигурок в хранилище для определенной расы
sub tokensInStorage {
  return $_[0]->{gameState}->{storage}->{$_[1]};
}

# возвращает может ли игрок атаковать регион (делает конечный подсчет фигурок,
# бросает кубик, если надо)
sub canAttack {
  my ($self, $player, $region, $race, $sp) = @_;
  my $regions = $self->{gameState}->{regions};
  $self->{conqNum} = $player->{tokensInHand} +
    $race->conquestRegionTokensBonus($player, $region, $regions);
  $self->{defendNum} = $region->getDefendTokensNum() +
    $sp->conquestRegionTokensBonus($region);

  if ( $self->{defendNum} - $self->{conqNum} > 0 && $self->{defendNum} - $self->{conqNum} <= 3 ) {
    # не хватает не больше 3 фигурок у игрока, поэтому бросаем кости
    $player->{dice} = $self->random();
  }

  # если игроку не хватает фигурок даже с подкреплением
  if ( $self->{conqNum} + $player->{dice} < $self->{defendNum} ) {
    $self->{gameState}->{state} = GS_FINISH_TURN;
    return 0;
  }
  return 1;
}

# возвращает может ли игрок, который должен защищаться, защищаться
sub canDefend {
  my ($self, $defender) = @_;
  # игрок может защищаться, если у него остались регионы, на которые он может
  # перемещать фигурки
  return grep {
    $defender->activeConq($_)
  } @{ $self->{gameState}->{regions} };
}

sub conquer {
  my ($self, $regionId) = @_;
  my $player = $self->getPlayer();
  my $region = $self->getRegion($regionId);
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  # если регион принадлежал активной расе
  if ( defined $region->{ownerId} ) {
    # то надо вернуть ему какие-то фигурки
    my $defender = $self->getPlayer( { id => $region->{ownerId} } );
    if ( $defender->activeConq($region) ) {
      my $defRace = $self->createRace($defender->{currentTokenBadge});
      $defender->{tokensNum} += $region->{tokensNum} + $defRace->looseTokensBonus();
      if ( $self->canDefend($defender) ) {
        $self->{gameState}->{conquerorId} = $player->{playerId};
        $self->{gameState}->{activePlayerId} = $defender->{playerId};
        $self->{gameState}->{state} = GS_DEFEND;
      }
    }
  }

  $region->{conquestIdx} = $self->nextConquestIdx();
  $region->{ownerId} = $player->{playerId};
  $region->{tokenBadgeId} = $player->{currentTokenBadge}->{tokenBadgeId};
  $region->{inDecline} = undef;
  $region->{tokensNum} = min($self->{defendNum}, $self->{conqNum}); # размещаем в регионе все фигурки, которые использовались для завоевания
  $player->{tokensInHand} -= $region->{tokensNum};  # убираем из рук игрока фигурки, которые оставили в регионе
}

sub decline {
  my ($self) = @_;
  my $player = $self->getPlayer();
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  foreach ( grep { $_->{ownerId} == $player->{playerId} } @{ $regions } ) {
    if ( $_->{inDecline} ) {
      $_->{inDecline} = undef;
      $_->{qw( ownerId tokenBadgeId tokensNum )} = [undef, undef, undef];
    }
    else {
      $_->{qw( inDecline tokensNum )} = [1, DECLINED_TOKENS_NUM];
    }
    $race->declineRegion($_);
    $sp->declineRegion($_);
  }
  my $badge = $player->{currentTokenBadge};
  $player->{qw( tokensInHand currentTokenBadge declineTokenBadge )} = [INITIAL_TOKENS_NUM, undef, $badge];
}

sub selectRace {
  my ($self, $p) = @_;
  my $player = $self->getPlayer();
  $player->{currentTokenBadge} = splice @{ $self->{gameState}->{tokenBadges} }, $p, 1;

  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  $player->{coins} -= $p;
  $player->{tokensInHand} = $race->initialTokens() + $sp->initialTokens();
  $self->{gameState}->{state} = GS_CONQUEST;
}

sub finishTurn {
  my $self = shift;
  my $player = $self->getPlayer();
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  $player->{coins} += 1 * grep {
    $_->{ownerId} == $player->{playerId}
  } @{ $regions } + $sp->coinsBonus() + $race->coinsBonus() + $sp->coinsBonus();
  delete $player->{dice};
  grep { $_->{conquestIdx} = undef } @{ $self->{gameState}->{regions} };
  $self->{gameState}->{activePlayerId} = $self->{gameState}->{players}->[
    ($player->{priority} + 1) / $self->{gameState}->{players} ]->{playerId};
  $player = $self->getPlayer();
  if ( $player->{priority} == 0 ) {
    $self->{gameState}->{currentTurn}++;
  }
  if ( $self->{gameState}->{currentTurn} ) {
    $self->{gameState}->{state} = GS_IS_OVER;
  }
  else {
    $self->{gameState}->{state} = defined $player->{currentTokenBadge}->{tokenBadgeId}
      ? GS_CONQUEST
      : GS_SELECT_RACE;
  }
}

sub redeploy {
  my ($self, $regs, $encampments, $fortified, $heroes) = @_;
  my $player = $self->getPlayer();

  foreach ( @{ $regs } ) {
    $self->getRegion($_->{regionId})->{tokensNum} = $_->{tokensNum};
    $player->{tokensInHand} -= $_->{tokensNum};
  }

  foreach ( @{ $encampments } ) {
    $self->getRegion($_->{regionId})->{encampment} = $_->{encampmentsNum};
  }

  if ( defined $fortified && defined $fortified->{regionId} ) {
    $self->getRegion($fortified->{regionId})->{fortified} = 1;
  }

  foreach ( @{ $heroes } ) {
    $self->getRegion($_->{regionId})->{hero} = 1;
  }
}

sub defend {
  my ($self, $regs) = @_;
  my $player = $self->getPlayer();
  
  foreach ( @{ $regs } ) {
    $self->getRegion($_->{regionId})->{tokensNum} = $_->{tokensNum};
    $player->{tokensNum} -= $_->{tokensNum};
  }
}

sub enchant {
  my ($self, $regionId) = @_;
  my $player = $self->getPlayer();
  $self->getRegion($regionId)->{qw( ownerId tokenBadgeId conquestIdx )} = [
      $player->{playerId}, $player->{currentTokenBadgeId}->{tokenBadgeId}, $self->nextConquestIdx() ];
  $self->{gameState}->{storage}->{&RACE_SORCERERS}--;
}

sub throwDice {
  my $self = shift;
  my $player = $self->getPlayer();
  $player->{dice} = $self->random();
  return $player->{dice};
}

1;

__END__
