package SmallWorld::Game;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );
use List::Util qw( min max);

use SmallWorld::Consts;
use SmallWorld::DB;
use SmallWorld::Player;
use SmallWorld::Races;
use SmallWorld::Region;
use SmallWorld::SpecialPowers;
use SmallWorld::Utils;

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
  $self->{gameState}->{$_} = $gs->{$_} for keys %$gs;
}

# загружает информацию об игре из БД
sub load {
  my ($self, $gameId, $act) = @_;
  my $game = $self->{db}->getGameState($gameId);
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

      ownerId          => undef,                                          # идентификатор игрока-владельца
      tokenBadgeId     => undef,                                          # идентификатор расы игрока-владельца
      tokensNum        => defined $_->{population} ? $_->{population}: 0, # количество фигурок
      conquestIdx      => undef,                                          # порядковый номер завоевания (обнуляется по окончанию хода)
      prevTokenBadgeId => undef,
      prevTokensNum    => undef,
      holeInTheGround  => undef,                                          # 1 если присутствует нора полуросликов
      lair             => undef,                                          # кол-во пещер троллей
      encampment       => undef,                                          # кол-во лагерей (какая осень в лагерях...)
      dragon           => undef,                                          # 1 если присутствует дракон
      fortiefied       => undef,                                          # кол-во фортов
      hero             => undef,                                          # 1 если присутствует герой
      inDecline        => undef                                           # 1 если раса tokenBadgeId в упадке
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
#      dice               => undef,                                       # число, которое выпало при броске костей берсерка
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
    defendingInfo  => undef
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
      tokenBadgeId     => ++$j,
      specialPowerName => splice(@sp, rand(scalar(@sp)), 1),
      bonusMoney       => 0
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
  $self->{db}->saveGameState(encode_json($gs), $gs->{activePlayerId}, $gs->{currentTurn}, $gs->{gameInfo}->{gameId});
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

sub getNotEmptyBadge {
  return defined $_[1] && defined $_[1]->{tokenBadgeId}
    ? \%{$_[1]}
    : undef;
}

# возвращает состояние игры для конкретного игрока (удаляет секретные данные)
sub getGameStateForPlayer {
  my $self = shift;
  my $gs = \%{ $self->{gameState} };
  $gs->{visibleTokenBadges} = [ @{ $gs->{tokenBadges} }[0..5] ];
  my $result = {
    gameId             => $gs->{gameInfo}->{gameId},
    gameName           => $gs->{gameInfo}->{gameName},
    gameDescription    => $gs->{gameInfo}->{gameDescription},
    currentPlayersNum  => $gs->{gameInfo}->{currentPlayersNum},
    activePlayerId     => defined $gs->{conquerorId} ? $gs->{conquerorId} : $gs->{activePlayerId},
    state              => !(grep { $_->{isReady} == 0 } @{ $gs->{players} }),
    stage              => $gs->{state},
    defendingInfo      => $gs->{defendingInfo},
    currentTurn        => $gs->{currentTurn},
    map                => \%{ $gs->{map} },
    visibleTokenBadges => $gs->{visibleTokenBadges},
    friendInfo         => $gs->{friendInfo},
    stoutStatistics    => $gs->{stoutStatistics},
    berserkDice        => $gs->{berserkDice},
    dragonAttacked     => $gs->{dragonAttacked},
    enchanted          => $gs->{enchanted},
    holesPlaced        => $gs->{holesPlaced},
    gotWealthy         => $gs->{gotWealthy}
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
        holeInTheGround => $self->bool($_->{holeInTheGround}),
        encampment      => $_->{encampment},
        dragon          => $self->bool($_->{dragon}),
        fortified       => $self->bool($_->{fortified}),
        hero            => $self->bool($_->{hero}),
        inDecline       => $self->bool($_->{inDecline})
      }
    }
  } @{ $gs->{regions} };
  $result->{players} = undef;
  grep {
    push @{ $result->{players} }, {
      userId             => $_->{playerId},
      username           => $_->{username},
      isReady            => $self->bool($_->{isReady}),
      coins              => $_->{coins},
      tokensInHand       => $_->{tokensInHand},
      priority           => $_->{priority} + 1,
      currentTokenBadge  => $self->getNotEmptyBadge($_->{currentTokenBadge}),
      declinedTokenBadge => $self->getNotEmptyBadge($_->{declinedTokenBadge})
    }
  } @{ $gs->{players} };
  foreach ( @{ $result->{players} } ) {
    if ( defined $_->{currentTokenBadge}->{tokenBadgeId} ) {
      $_->{currentTokenBadge}->{totalTokensNum} = $_->{tokensInHand} +
        $self->getTokensNum($_->{currentTokenBadge}->{tokenBadgeId});
    }
    if ( $_->{declinedTokenBadge}->{tokenBadgeId} ) {
      $_->{declinedTokenBadge}->{totalTokensNum} =
        $self->getTokensNum($_->{declinedTokenBadge}->{tokenBadgeId});
    }
  }
  $self->removeNull($result);
  return $result;
}

sub getTokensNum {
  my ($self, $tokenBadgeId) = @_;
  my $result = 0;
  foreach ( @{ $self->{gameState}->{regions} } ) {
    $result += $_->{tokensNum} if ($_->{tokenBadgeId} // -1) == $tokenBadgeId;
  }
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
      &SP_COMMANDO      => 'SmallWorld::SpCommando',
      &SP_DIPLOMAT      => 'SmallWorld::SpDiplomat',
      &SP_DRAGON_MASTER => 'SmallWorld::SpDragonMaster',
      &SP_FLYING        => 'SmallWorld::SpFlying',
      &SP_FOREST        => 'SmallWorld::SpForest',
      &SP_FORTIFIED     => 'SmallWorld::SpFortified',
      &SP_HEROIC        => 'SmallWorld::SpHeroic',
      &SP_HILL          => 'SmallWorld::SpHill',
      &SP_MERCHANT      => 'SmallWorld::SpMerchant',
      &SP_MOUNTED       => 'SmallWorld::SpMounted',
      &SP_PILLAGING     => 'SmallWorld::SpPillaging',
      &SP_SEAFARING     => 'SmallWorld::SpSeafaring',
      &SP_STOUT         => 'SmallWorld::SpStout',
      &SP_SWAMP         => 'SmallWorld::SpSwamp',
      &SP_UNDERWORLD    => 'SmallWorld::SpUnderworld',
      &SP_WEALTHY       => 'SmallWorld::SpWealthy'
    }->{ $badge->{specialPowerName} };
  }
  return $power->new($player, $self->{gameState}, $badge);
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
  return grep $region->{$_}, qw( holeInTheGround dragon hero );
}

# возвращает следующий порядковый номер завоевания регионов
sub nextConquestIdx {
  my $result = -1;
  grep { $result = max( $result, defined $_->{conquestIdx} ? $_->{conquestIdx} : -1 ) } @{ $_[0]->{gameState}->{regions} };
  return $result + 1;
}

# бросаем кубик (возвращает число от 0 до 3) (кубик имеет три нулевых грани и
# три грани 1,2,3)
sub random {
  return 0 if $ENV{DEBUG};
  return int(rand(1)) * (int(rand(2)) + 1);
}

# возвращает количество фигурок в хранилище для определенной расы
sub tokensInStorage {
  return $_[0]->{gameState}->{storage}->{$_[1]};
}

# возвращает может ли игрок атаковать регион при первом завоевании
sub canFirstConquer {
  my ($self, $region, $race, $sp) = @_;
  my $regions = $self->{gameState}->{regions};

  #можно захватить любой регион соседствующий с морем, которое является гранцией
  #можно захватить любой приграничный не морской регион
  #нельзя захватывать моря и озера,
  my $ adj = 0;
  foreach my $i ( @{$region->{adjacentRegions}} ) {
    my ($isSea, $isBorder) = (0, 0);
    foreach ( @{$regions->[$i-1]->{constRegionState}} ){
      $isBorder = 1 if $_ eq REGION_TYPE_BORDER;
      $isSea = 1 if $_ eq REGION_TYPE_SEA;
    }
    $adj = 1 if $isSea && $isBorder;
  }

  return
    !(grep { $_ eq REGION_TYPE_SEA } @{ $region->{constRegionState} }) &&
    ((grep { $_ eq REGION_TYPE_BORDER } @{ $region->{constRegionState} }) || $adj) ||
    $race->canFirstConquer($region) || $sp->canFirstConquer($region);
}

# возвращает хватает ли игроку фигурок для атаки региона (бросает кубик, если надо)
sub canAttack {
  my ($self, $player, $region, $race, $sp, $result) = @_;
  my $regions = $self->{gameState}->{regions};

  $self->{defendNum} = max(1, $region->getDefendTokensNum() -
    $sp->conquestRegionTokensBonus($region) - $race->conquestRegionTokensBonus($player, $region, $regions, $sp));

  if ( !defined $self->{gameState}->{berserkDice} && ($self->{defendNum} - $player->{tokensInHand}) ~~ [1..3] ) {
    # не хватает не больше 3 фигурок у игрока, поэтому бросаем кости, если еще не кинули(berserk)
    $player->{dice} = $self->random();
    $result->{dice} = $player->{dice};
  }

  # если игроку не хватает фигурок даже с подкреплением, это его последнее завоевание
  if ( $player->{tokensInHand} + $player->safe('dice') < $self->{defendNum} ) {
    # если у игрока нет территорий то ждем команды конец хода
    $self->{gameState}->{state} = (grep { $player->activeConq($_) } @{ $regions }) ?
                                  GS_REDEPLOY : GS_BEFORE_FINISH_TURN;
    return 0;
  }
  return 1;
}

# возвращает может ли игрок, который должен защищаться, защищаться
sub canDefend {
  my ($self, $defender, $tokens) = @_;
  # игрок может защищаться, если у него остались регионы, на которые он может
  # перемещать фигурки и на руках есть фигурки расы
  return $tokens &&
  return grep { $defender->activeConq($_) } @{ $self->{gameState}->{regions} };
}

sub conquer {
  my ($self, $regionId, $result) = @_;
  my $player = $self->getPlayer();
  my ($defender, $defTokens) = ();
  my $region = $self->getRegion($regionId);
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  if ( defined $region->{ownerId} ) {
    $defender = $self->getPlayer( { id => $region->{ownerId} } );
    # если регион принадлежал активной расе
    if ( $defender->activeConq($region) ) {
      # то надо вернуть ему какие-то фигурки
      my $defRace = $self->createRace($defender->{currentTokenBadge});
      $defTokens = $region->{tokensNum} + $defRace->looseTokensBonus();
#      $defender->{tokensInHand} += $region->{tokensNum} + $defRace->looseTokensBonus();
    }
    else {
      # иначе защищающийся ничего не делает
      $defender = undef;
    }
  }

  $region->{conquestIdx} = $self->nextConquestIdx();
  $region->{prevTokenBadgeId} = $region->{tokenBadgeId};
  $region->{prevTokensNum} = $region->{tokensNum};
  $region->{ownerId} = $player->{playerId};
  $region->{tokenBadgeId} = $player->{currentTokenBadge}->{tokenBadgeId};
  @{ $region }{ qw(inDecline lair fortified encampment) } = ();
  $region->{tokensNum} = min($self->{defendNum}, $player->{tokensInHand}); # размещаем в регионе все фигурки, которые использовались для завоевания
  $race->placeObject($self->{gameState}, $region)                          # размещаем в регионе уникальные для рас объекты
    if $race->canPlaceObj2Region($player, $self->{gameState}, $region);
  $player->{tokensInHand} -= $region->{tokensNum};  # убираем из рук игрока фигурки, которые оставили в регионе

  if ( defined $defender ) {
    $defender->{tokensInHand} = $defTokens;
    if ($self->canDefend($defender, $defTokens)) {
      $self->{gameState}->{defendingInfo} = {
        'playerId' => $defender->{playerId},
        'regionId' => $region->{regionId}
      };
      $self->{gameState}->{conquerorId} = $player->{playerId};
      $self->{gameState}->{activePlayerId} = $defender->{playerId};
      $self->{gameState}->{state} = GS_DEFEND;
    }
  }
  $self->{gameState}->{berserkDice} = undef if exists $self->{gameState}->{berserkDice};

  if ( defined $player->{dice} ) {
    $result->{dice} = $player->{dice};
    $player->{dice} = undef;
  }
  $self->{gameState}->{state} = GS_CONQUEST if $self->{gameState}->{state} eq GS_BEFORE_CONQUEST;
}

sub decline {
  my ($self) = @_;
  my $player = $self->getPlayer();
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);
  my $dsp = $self->createSpecialPower('declinedTokenBadge', $player);
  my $drace = $self->createRace($player->{declinedTokenBadge});

  if ($self->{gameState}->{state} eq GS_BEFORE_FINISH_TURN) {
    $self->{gameState}->{stoutStatistics} = [];
    $self->getPlayerBonus($player, $self->{gameState}, $self->{gameState}->{stoutStatistics});
  }
  foreach ( grep { defined $_->{ownerId} && $_->{ownerId} == $player->{playerId} } @{ $regions } ) {
    if ( $_->{inDecline} ) {
      $_->{inDecline} = undef;
      @{ $_ }{qw( ownerId tokenBadgeId tokensNum )} = (undef, undef, undef);
      $drace->abandonRegion($_);
      $dsp->abandonRegion($_);
    }
    else {
      @{ $_ }{qw( inDecline tokensNum )} = (1, DECLINED_TOKENS_NUM);
      $race->declineRegion($_);
      $sp->declineRegion($_);
    }
  }
  my $badge = $player->{currentTokenBadge};
  @{ $player }{qw( tokensInHand currentTokenBadge declinedTokenBadge )} = (INITIAL_TOKENS_NUM, undef, $badge);
  $self->{gameState}->{state} = GS_FINISH_TURN;
}

sub selectRace {
  my ($self, $p, $result) = @_;
  my $player = $self->getPlayer();

  ++$self->{gameState}->{tokenBadges}->[$_]->{bonusMoney} for (0..$p-1);

  $player->{currentTokenBadge} = splice @{ $self->{gameState}->{tokenBadges} }, $p, 1;
  $result->{tokenBadgeId} = $player->{currentTokenBadge}->{tokenBadgeId};

  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);
  $sp->activate($self->{gameState}, $player);
  $race->activate($self->{gameState});

  $player->{coins} += $player->{currentTokenBadge}->{bonusMoney} - $p;
  delete $player->{currentTokenBadge}->{bonusMoney};
  $player->{tokensInHand} = $race->initialTokens() + $sp->initialTokens() + $race->conquestTokensBonus();
  $self->{gameState}->{state} = GS_CONQUEST;
}

sub getPlayerBonus {
  my ($self, $player, $state, $result) = @_;
  my $regions = $state->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $drace = $self->createRace($player->{declinedTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  my $regionBonus = 1 * (grep { defined $_->{ownerId} && $_->{ownerId} == $player->{playerId}} @{ $regions });
  my $bonus = $regionBonus + $sp->coinsBonus($self->{gameState}) + $race->coinsBonus() + $drace->declineCoinsBonus();
  push @{$result}, ['Regions', $regionBonus];
  if (defined $player->{currentTokenBadge}->{raceName} ){
    push @{ $result }, [$player->{currentTokenBadge}->{raceName}, $race->coinsBonus()];
    push @{ $result }, [$player->{currentTokenBadge}->{specialPowerName}, $sp->coinsBonus($self->{gameState})];
  }
  if (defined $player->{declinedTokenBadge}->{raceName} ){
    push @{ $result }, [$player->{declinedTokenBadge}->{raceName}, $drace->declineCoinsBonus()];
    push @{ $result }, [$player->{declinedTokenBadge}->{specialPowerName}, 0];
  }
  return $bonus;
}

sub finishTurn {
  my ($self, $result) = @_;
  my $player = $self->getPlayer();
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $drace = $self->createRace($player->{declinedTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  # возвращаем количество монет, полученных на этом ходу
  my $bonus = 0;
  if (defined $self->{gameState}->{stoutStatistics}) {
    $bonus += $_->[1] for @{$self->{gameState}->{stoutStatistics}};
    @ {$result->{statistics} } = @{ $self->{gameState}->{stoutStatistics} };
    delete $self->{gameState}->{stoutStatistics};
  } else {
    $result->{statistics} = [];
    $bonus = $self->getPlayerBonus($player, $self->{gameState}, $result->{statistics});
  }
  $player->{coins} += $bonus;

  $sp->finishTurn($self->{gameState});
  $race->finishTurn($self->{gameState});
  $self->{gameState}->{friendInfo}->{friendId} = undef
    if defined $self->{gameState}->{friendInfo} && ($self->{gameState}->{friendInfo}->{friendId} // -1) == $player->{playerId};

  @ {$_}{qw (conquestIdx prevTokenBadgeId)} = () for @{ $self->{gameState}->{regions} };

  $self->{gameState}->{activePlayerId} = $self->{gameState}->{players}->[
    ($player->{priority} + 1) % scalar(@{ $self->{gameState}->{players} }) ]->{playerId};

  $player = $self->getPlayer();
  if ( $player->{priority} == 0 ) {
    $self->{gameState}->{currentTurn}++;
  }
  if ( $self->{gameState}->{currentTurn} >= $self->{gameState}->{map}->{turnsNum}) {
    $self->{gameState}->{state} = GS_IS_OVER;
  }
  elsif ( defined $player->{currentTokenBadge}->{tokenBadgeId} ) {
    $self->{gameState}->{state} = GS_BEFORE_CONQUEST;

    #оставляем на территориях по одной фигурке рас, остальные даем игроку в руки
    $race = $self->createRace($player->{currentTokenBadge});
    $player->{tokensInHand} += $race->conquestTokensBonus();
    foreach ( @{$race->{regions}} ) {
      $player->{tokensInHand} += $_->{tokensNum} - 1;
      $_->{tokensNum} = 1;
    }
  } else {
    $self->{gameState}->{state} = GS_SELECT_RACE;
  }
}

sub redeploy {
  my ($self, $regs, $encampments, $fortified, $heroes) = @_;
  my $player = $self->getPlayer();
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);
  my $lastRegion = defined $regs->[-1] ? $self->getRegion($regs->[-1]->{regionId}): undef;

  $player->{tokensInHand} += $race->redeployTokensBonus($player);
  foreach ( @{ $race->{regions} } ) {
    $player->{tokensInHand} += $_->{tokensNum};
    @ {$_}{qw (tokensNum encampment hero) } = (0, undef, undef);
  }
  foreach ( @{ $regs } ) {
    $self->getRegion($_->{regionId})->{tokensNum} = $_->{tokensNum};
    $player->{tokensInHand} -= $_->{tokensNum};
  }
  foreach ( @{ $race->{regions} } ) {
    if (!$_->{tokensNum}) {
      $race->abandonRegion($_);
      $sp->abandonRegion($_);
      delete $_->{ownerId};
      delete $_->{tokenBadgeId};
    }
  }

  if ( defined $lastRegion ) {
    $lastRegion->{tokensNum} += $player->{tokensInHand};
    $player->{tokensInHand} = 0;
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
  $self->{gameState}->{state} = GS_BEFORE_FINISH_TURN;
}

sub defend {
  my ($self, $regs) = @_;
  my $player = $self->getPlayer();
  $player->{tokensInHand} = 0;
  foreach ( @{ $regs } ) {
    $self->getRegion($_->{regionId})->{tokensNum} += $_->{tokensNum};
  }
  $self->{gameState}->{activePlayerId} = $self->{gameState}->{conquerorId};
  @{ $self->{gameState} }{qw(defendingInfo conquerorId)} = ();
  $self->{gameState}->{state} = GS_CONQUEST;
}

sub enchant {
  my ($self, $regionId) = @_;
  my $player = $self->getPlayer();

  @{ $self->getRegion($regionId) }{qw( ownerId tokenBadgeId conquestIdx )} = (
      $player->{playerId}, $player->{currentTokenBadge}->{tokenBadgeId}, $self->nextConquestIdx() );
  $self->{gameState}->{storage}->{&RACE_SORCERERS} -= 1;
  $self->{gameState}->{enchanted} = 1;
  $self->{gameState}->{state} = GS_CONQUEST if $self->{gameState}->{state} eq GS_BEFORE_CONQUEST;
}

sub selectFriend {
  my ($self, $friendId) = @_;
#  my $player = $self->getPlayer({ id => $friendId });
  $self->{gameState}->{friendInfo}->{friendId} = $self->getPlayer({ id => $friendId })->{playerId};
}

sub dragonAttack {
  my ($self, $regionId) = @_;
  foreach ( @{ $self->{gameState}->{regions} } ) {
    $_->{dragon} = undef;
  }
  my $region = $self->getRegion($regionId);
  $self->{defendNum} = 1;
  $self->conquer($regionId);
  $self->{gameState}->{dragonAttacked} = 1;
  $region->{dragon} = 1;
}

sub throwDice {
  my ($self, $dice) = @_;
  my $player = $self->getPlayer();
  $self->{gameState}->{berserkDice} = $ENV{DEBUG} && defined $dice ? $dice : $self->random();
  $self->{gameState}->{state} = GS_CONQUEST if $self->{gameState}->{state} eq GS_BEFORE_CONQUEST;
  return $self->{gameState}->{berserkDice};
}

1;

__END__
