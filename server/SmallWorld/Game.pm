package SmallWorld::Game;


use strict;
use warnings;
use utf8;

use JSON qw(decode_json encode_json);

use SmallWorld::Consts;
use SmallWorld::DB;

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

# загружает информацию об игре из БД
sub load {
  my ($self, $sid) = @_;
  my $game = $self->{db}->getGameState($sid);
  use Data::Dumper; print Dumper($game);
  my $gs = decode_json($game->{state} || '');
  my $map = $self->{db}->getMap($game->{mapId});
  $self->{gameState} = {
    gameInfo           => {
      gameId            => $game->{id},
      gameName          => $game->{name},
      gameDescription   => $game->{description},
      currentPlayersNum => $game->{currentPlayersNum}
    },
    map                => {
      mapId      => $game->{mapId},
      mapName    => $map->{name},
      turnsNum   => $map->{turnsNum},
      playersNum => $map->{playersNum},
    },
    activePlayerId     => $gs->{activePlayerId},
    state              => $gs->{state},
    currentTurn        => $gs->{currentTurn},
    regions            => $gs->{regions},
    players            => $gs->{players},
    visibleTokenBadges => $gs->{tokenBadges},
  };

  if ( !defined $self->{gameState}->{regions} ) {
    my $regions = decode_json($map->{regions});
    my $i = 0;
    $self->{gameState}->{regions} = [
      map { {
        regionId           => $i++,
        constRegionState   => $_->{landDescription},
        adjacentRegions    => $_->{adjacent},
        currentRegionState => {
          ownerId         => undef,            # идентификатор игрока-владельца
          tokenBadgeId    => undef,            # идентификатор расы игрока-владельца
          tokensNum       => $_->{population}, # количество фигурок
          conquered       => undef,            # 1 если завоеван на этом ходу
          holeInTheGround => undef,            # 1 если присутствует нора полуросликов
          lair            => undef,            # кол-во пещер троллей
          encampment      => undef,            # кол-во лагерей (какая осень в лагерях...)
          dragon          => undef,            # 1 если присутствует дракон
          fortiefied      => undef,            # кол-во фортов
          hero            => undef,            # 1 если присутствует герой
          inDecline       => undef             # 1 если раса tokenBadgeId в упадке
        }
     } } @{$regions}
    ];
  }

  if ( !defined $self->{gameState}->{players} ) {
    my $players = $self->{db}->getPlayers($game->{id});
    my $i = 0;
    $self->{gameState}->{players} = [
      map { {
        userId             => $_->{id},
        username           => $_->{username},
        isReady            => $_->{isReady},
        coins              => INITIAL_COINS_NUM,
        tokensInHand       => INITIAL_TOKENS_NUM,
        priority           => $i++,
        currentTokenBadge  => {
          tokenBadgeId     => undef,
          totalTokensNum   => undef,
          raceName         => undef,
          specialPowerName => undef
        },
        declinedTokenBadge => undef
      } } @{$players}
    ];
  }
}

# сохраняет состояние игры в БД
sub save {
  my $self = shift;
  my $gs = %{ $self->{gameState} };
  $gs->{tokenBadges} = $gs->{visibleTokenBadges};
  delete $gs->{visibleTokenBadges};
  delete $gs->{gameInfo};
  delete $gs->{map};
  $self->{db}->saveGameState(encode_json($gs), $self->{gameState}->{gameInfo}->{gameId});
}

# возвращает состояние игры для конкретного игрока (удаляет секретные данные)
sub getGameStateForPlayer {
  my $self = shift;
  my $gs = %{ $self->{gameState} };
  grep {delete $_->{coins}} @{ $gs->{players} };
  $gs->{visibleTokenBadges} = @{ $gs->{visibleTokenBadges} }[0..5];
  return $gs;
}

# возвращает кол-во регионов в игре
sub regionsNum {
  return $@{ $_[0]->{gameState}->{regions} };
}

# возвращает игрока из массива игроков по id или sid
sub getPlayer {
  my ($self, $param) = @_;
  my $id = $param->{id};
  if ( defined $param->{sid} ) {
    $id = $self->{db}->getPlayerId($param->{sid});
  }
  elsif ( !defined $id ) {
    $id = $self->{gameState}->{activePlayerId};
  }

  # находим в массиве игроков текущего игрока
  foreach ( @{ $self->{gameState}->{players} } ) {
    return $_ if $_->{userId} == $id;
  }
}

# возвращает регион из массива регионов по id
sub getRegion {
  my ($self, $id) = @_;
  foreach ( @{ $self->{gameState}->{regions} } ) {
    return $_ if $_->{regionId} == $id;
  }
}

# возвращает объект класса, который соответсвует расе
sub createRace {
  my ($self, $badge) = @_;
  return SmallWorld::BaseRace->new() if !defined $badge || !defined $badge->{raceName};

  my %races = {
    amazons   => "SmallWorld::RaceAmazons",
    dwarves   => "SmallWorld::RaceDwarves",
    elves     => "SmallWorld::RaceElves",
    giants    => "SmallWorld::RaceGiants",
    halflings => "SmallWorld::RaceHalflings",
    humans    => "SmallWorld::RaceHumans",
    orcs      => "SmallWorld::RaceOrcs",
    ratmen    => "SmallWorld::RaceRatmen",
    skeletens => "SmallWorld::RaceSkeletons",
    sorcerers => "SmallWorld::RaceSorcerers",
    tritons   => "SmallWorld::RaceTritons",
    trolls    => "SmallWorld::RaceTrolls",
    wizards   => "SmallWorld::RaceWizards"
  };
  return $races{ $badge->{raceName} }->new();
}

# возвращает объект класса, который соответствует способности
sub createSpecialPower {
  my ($self, $badge) = @_;
  return SmallWorld::BaseSp->new() if !defined $badge || !defined $badge->{specialPowerName};

  my %powers = {
    alchemist    => 'SmallWorld::SpAlchemist',
    berserk      => 'SmallWorld::SpBerserk',
    bivouacking  => 'SmallWorld::SpBivouacking',
    commando     => 'SmallWorld::SpCommado',
    diplomat     => 'SmallWorld::SpDiplomat',
    dragonMaster => 'SmallWorld::SpDragonMaster',
    flying       => 'SmallWorld::SpFlying',
    forest       => 'SmallWorld::SpForest',
    fortified    => 'SmallWorld::SpFortified',
    heroic       => 'SmallWorld::SpHeroic',
    hill         => 'SmallWorld::SpHill',
    merchant     => 'SmallWorld::SpMerchant',
    pillaging    => 'SmallWorld::SpPillaging',
    seafaring    => 'SmallWorld::SpSeafaring',
    stout        => 'SmallWorld::SpStout',
    swamp        => 'SmallWorld::SpSwamp',
    underworld   => 'SmallWorld::SpUnderworld',
    wealthy      => 'SmallWorld::SpWealthy'
  };
  return $powers{ $badge->{specialPowerName} }->new();
}

sub isFirstConquer {
  my $playerId = $_[0]->{gameState}->{activePlayerId};
  foreach ( @{ $_[0]->{gameState}->{regions} } ) {
    return 0 if $_->{ownerId} == $playerId;
  }
  return 1;
}

sub conquer {
  my ($self, $regionId) = @_;
  my $player = $self->getPlayer();
  my $region = $self->getRegion($regionId);
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge}->{raceName});
  my $sp = $self->createSpecialPower($player->{currentTokenBadge}->{specialPowerName});

  # 1. свои регионы с активной расой захватывать нельзя
  # 2. на первом завоевании можно захватывать далеко не все регионы
  # 3. а вдруг у территории иммунитет?
  return R_BAD_REGION if ($region->{ownerId} != $player->{playerId} || $region->{inDecline}) &&
    !($self->isFirstConquer() && $race->canFirstConquer($region)) &&
    !$sp->canAttack($player, $region, $regions);

  my $realTokens = $player->{tokensInHand} + $race->conquestTokensBonus();
  return R_BAD_STAGE if $realTokens < 1;
  my $conqNum = $realTokens +
    $race->conquestRegionTokensBonus($player, $region, $regions);
  my $defendNum = $region->{tokensNum} +
    $self->defendRegionTokensBonus() +
    $sp->conquestRegionTokensBonus($region);

  if ( $conqNum < $defendNum ) {
#$conqNum =
  }

  return R_BAD_REGION if $conqNum < $defendNum;

  if ( defined $region->{ownerId} ) {
    my $defender = $self->getPlayer( { id => $region->{ownerId} } );
    my $defRace = $self->createRace($defender->{currentTokenBadge}->{raceName});
    $defender->{tokensNum} += $region->{tokensNum} + $defRace->looseTokensBonus();
  }

#$region->{tokensNum} = $defendNum
  return R_ALL_OK;
}

sub decline {
  my ($self) = @_;
  my $player = $self->getPlayer();
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge}->{raceName});
  my $sp = $self->createRace($player->{currentTokenBadge}->{specialPowerName});

  foreach ( grep { $_->{ownerId} == $player->{playerId} } @{ $regions } ) {
    if ( $_->{inDecline} ) {
      $_->{inDecline} = undef;
      $_->{currentRegionState}->{qw( ownerId tokenBadgeId tokensNum )} = (undef, undef, undef );
    }
    else {
      $_->{qw( inDecline tokensNum )} = (1, DECLINED_TOKENS_NUM);
    }
    $race->declineRegion($_);
    $sp->declineRegion($_);
  }
  my $badge = $player->{currentTokenBadge};
  $player->{qw( tokensInHand currentTokenBadge declineTokenBadge )} = (INITIAL_TOKENS_NUM, undef, $badge);
}

1;

__END__
