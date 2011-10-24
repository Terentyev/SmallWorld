package SmallWorld::Game;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );
use List::Util qw( min );

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
  my $gs = defined $game->{STATE}
    ? decode_json($game->{STATE})
    : {};
  my $map = $self->{db}->getMap($game->{MAPID});
  $self->{gameState} = {
    gameInfo       => {
      gameId            => $game->{ID},
      gameName          => $game->{NAME},
      gameDescription   => $game->{DESCRIPTION},
      currentPlayersNum => $game->{CURRENTPLAYERSNUM}
    },
    map            => {
      mapId      => $game->{MAPID},
      mapName    => $map->{NAME},
      turnsNum   => $map->{TURNSNUM},
      playersNum => $map->{PLAYERSNUM},
    },
    activePlayerId => $gs->{activePlayerId},
    state          => $gs->{state},
    currentTurn    => $gs->{currentTurn},
    regions        => $gs->{regions},
    players        => $gs->{players},
    tokenBadges    => $gs->{tokenBadges},
  };

  if ( !defined $self->{gameState}->{regions} ) {
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
  }

  if ( !defined $self->{gameState}->{players} ) {
    my $players = $self->{db}->getPlayers($game->{ID});
    my $i = 0;
    $self->{gameState}->{players} = [
      map { {
        userId             => $_->{ID},
        username           => $_->{USERNAME},
        isReady            => 1 * $_->{ISREADY},
        coins              => undef,
        tokensInHand       => undef,
        priority           => $i++,
        finishConquest     => undef,              # 1 если продолжать атаковать игрок не может
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
  my $gs = \%{ $self->{gameState} };
  delete $gs->{gameInfo};
  delete $gs->{map};
  $self->{db}->saveGameState(encode_json($gs), $self->{gameState}->{gameInfo}->{gameId});
}

# возвращает состояние игры для конкретного игрока (удаляет секретные данные)
sub getGameStateForPlayer {
  my $self = shift;
  my $gs = \%{ $self->{gameState} };
  $gs->{visibleTokenBadges} = @{ $gs->{tokenBadges} }[0..5];
  my $result = {
    gameId             => $gs->{gameInfo}->{gameId},
    gameName           => $gs->{gameInfo}->{gameName},
    gameDescription    => $gs->{gameInfo}->{gameDescription},
    currentPlayersNum  => $gs->{gameInfo}->{currentPlayersNum},
    activePlayerId     => $gs->{activuPlayerId},
    state              => $gs->{state},
    currentTurn        => $gs->{currentTurn},
    map                => \%{ $gs->{map} },
    visibleTokenBadges => \@{ $gs->{visibleTokenBadges} }
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
      userId => $_->{userId},
      username => $_->{username},
      isReady  => $_->{isReady},
      coins    => $_->{coins},
      tokensInHand => $_->{tokensInHand},
      priority     => $_->{priority},
      currentTokenBadge => \%{ $_->{currentTokenBadge} },
      declineTokenBadge => \%{ $_->{declineTokenBadge} }
    }
  } @{ $gs->{players} };
  grep {delete $_->{coins}} @{ $result->{players} };
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

# возвращает первое ли это нападение (есть ли на карте регионы с это 
sub isFirstConquer {
  my $playerId = $_[0]->{gameState}->{activePlayerId};
  return grep {
    $_->{ownerId} == $playerId && !$_->{inDecline}
  } @{ $_[0]->{gameState}->{regions} };
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

sub conquer {
  my ($self, $regionId, $result) = @_;
  my $player = $self->getPlayer();
  my $region = $self->getRegion($regionId);
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge}->{raceName});
  my $sp = $self->createSpecialPower($player->{currentTokenBadge}->{specialPowerName});

  # 1. свои регионы с активной расой захватывать нельзя
  # 2. на первом завоевании можно захватывать далеко не все регионы
  # 3. а вдруг у территории иммунитет?
  # 4. и вообще есть куча правил нападения на регионы (если это не первое нападение)
  if ( ($region->{ownerId} == $player->{playerId} && !$region->{inDecline}) ||
    $self->isFirstConquer() && !$race->canFirstConquer($region) ||
    $self->isImmuneRegion($region) ||
    $sp->canAttack($player, $region, $regions)
  ) {
    $result->{result} = R_BAD_REGION;
    return;
  }

  my $conqNum = $player->{tokensInHand};
  # игрок обязан на руках иметь хотя бы одну фигурку и он не должен был
  # совершать последнее завоевание с бросанием кубиков
  if ( $conqNum < 1 && !$player->{finishConquest} ) {
    $result->{result} = R_BAD_STAGE;
    return;
  }

  $conqNum += $race->conquestRegionTokensBonus($player, $region, $regions);
  my $defendNum = $region->{tokensNum} +
    $self->defendRegionTokensBonus() +
    $sp->conquestRegionTokensBonus($region);

  my $dice = 0;
  if ( $defendNum - $conqNum > 0 && $defendNum - $conqNum <= 3 ) {
    # не хватает не больше 3 фигурок у игрока, поэтому бросаем кости
    $dice = $self->random();
    $result->{dice} = $dice;
  }

  # если игроку не хватает фигурок даже с подкреплением
  if ( $conqNum + $dice < $defendNum ) {
    $result->{result} = R_BAD_REGION;
    $player->{finishConquest} = 1;
    return;
  }

  # если регион принадлежал активной расе
  if ( defined $region->{ownerId} ) {
    # то надо вернуть ему какие-то фигурки
    my $defender = $self->getPlayer( { id => $region->{ownerId} } );
    my $defRace = $self->createRace($defender->{currentTokenBadge}->{raceName});
    $defender->{tokensNum} += $region->{tokensNum} + $defRace->looseTokensBonus();
  }

  $region->{tokensNum} = min($defendNum, $conqNum); # размещаем в регионе все фигурки, которые использовались для завоевания
  $player->{tokensInHand} -= $region->{tokensNum};  # убираем из рук игрока фигурки, которые оставили в регионе
  $region->{conquestIdx} = $self->nextCotquestIdx();
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
      $_->{qw( ownerId tokenBadgeId tokensNum )} = (undef, undef, undef );
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
