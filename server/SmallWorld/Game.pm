package SmallWorld::Game;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );
use List::Util qw( min max );

use SW::Util qw( swLog );

use SmallWorld::Config;
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
  my $self = { gameState => undef };

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
  my $self = shift;
  my %params = (@_);

  if ( defined $params{id} && defined $params{db} ) {
    $self->loadFromDB(%params);
  }
  else {
    $self->loadFromState(%params);
  }
}

sub loadFromState {
  my $self = shift;
  my %params = (@_);
  my %gs = %{ $params{gameState} };
  $self->{gameState} = {
    gameInfo       => {
      gameId            => $gs{gameId},
      gameName          => $gs{gameName},
      gameDescription   => $gs{gameDescription},
      currentPlayersNum => $gs{currentPlayersNum},
      gstate            => $gs{state}
    },
    map            => {
      mapId      => $gs{map}->{mapId},
      mapName    => $gs{map}->{mapName},
      turnsNum   => $gs{map}->{turnsNum},
      playersNum => $gs{map}->{playersNum}
    },
    regions        => [],
    players        => [],
    activePlayerId => $gs{defendingInfo}->{playerId} // $gs{activePlayerId},
    conquerorId    => $gs{defendingInfo}->{playerId}
                      ? $gs{activePlayerId}
                      : undef,
    currentTurn    => $gs{currentTurn},
    tokenBadges    => $gs{visibleTokenBadges},
    friendInfo     => $gs{friendInfo},
    stoutStatistcs => $gs{stoutStatistics},
    berserkDice    => $gs{berserkDice},
    dragonAttacked => $gs{dragonAttacked} ? 1 : 0,
    enchanted      => $gs{enchanted} ? 1 : 0,
    holesPlaced    => $gs{holesPlaced},
    gotWealthy     => $gs{gotWealthy} ? 1 : 0
  };
  my $state = $self->getStageFromGameState(\%gs);
  die "Wrong calculate stage: $gs{stage} vs $state\n"
    if defined $gs{stage} && $gs{stage} ne $state && ($gs{state} == GST_BEGIN || $gs{state} == GST_IN_GAME);
  $self->{gameState}->{state} = $state;
  my $i = 0;
  foreach ( @{ $gs{map}->{regions} } ) {
    ++$i;
    push @{ $self->{gameState}->{regions} }, {
      regionId          => $i,
      constRegionState => $_->{constRegionState},
      adjacentRegions   => $_->{adjacentRegions},
      ownerId           => $_->{currentRegionState}->{ownerId},
      tokenBadgeId      => $_->{currentRegionState}->{tokenBadgeId},
      tokensNum         => $_->{currentRegionState}->{tokensNum},
      holeInTheGround   => $_->{currentRegionState}->{holeInTheGround} ? 1 : 0,
      lair              => $self->getLairFromGameState(\%gs, $_->{currentRegionState}->{tokenBadgeId}),
      encampment        => $_->{currentRegionState}->{encampment},
      dragon            => $_->{currentRegionState}->{dragon} ? 1 : 0,
      fortified         => $_->{currentRegionState}->{fortified} ? 1 : 0,
      hero              => $_->{currentRegionState}->{hero} ? 1 : 0,
      inDecline         => $_->{currentRegionState}->{inDecline} ? 1 : 0,
      conquestIdx       => ((defined $gs{defendingInfo} ? $gs{defendingInfo}->{regionId} : undef) // -1) == $i
        ? 1 : undef
    };
  }
  foreach ( @{ $gs{players} } ) {
    push @{ $self->{gameState}->{players} }, {
      playerId           => $_->{userId},
      username           => $_->{username},
      isReady            => $_->{isReady} ? 1 : 0,
      inGame             => $_->{inGame} ? 1 : 0,
      coins              => $_->{coins},
      tokensInHand       => $_->{tokensInHand},
      priority           => $_->{priority} - 1,
      currentTokenBadge  => $_->{currentTokenBadge} // {},
      declinedTokenBadge => $_->{declinedTokenBadge} // {}
    };
  }
}

sub getLairFromGameState {
  my ($self, $gs, $tokenBadgeId) = @_;
  return undef if !defined $tokenBadgeId;
  return (grep {
      defined $_->{currentTokenBadge} && ($_->{currentTokenBadge}->{tokenBadgeId} // -1) == $tokenBadgeId &&
      $_->{currentTokenBadge}->{raceName} eq RACE_TROLLS ||
      defined $_->{declinedTokenBadge} && ($_->{declinedTokenBadge}->{tokenBadgeId} // -1) == $tokenBadgeId &&
      $_->{declinedTokenBadge}->{raceName} eq RACE_TROLLS
    } @{ $gs->{players} })
    ? 1 : undef;
}

sub getStageFromGameState {
  my ($self, $gs) = @_;
  my $st = $gs->{state};
  return undef if $st == GST_WAIT;
  return GS_SELECT_RACE if $st == GST_BEGIN;
  return GS_IS_OVER     if $st == GST_FINISH || $st == GST_EMPTY;

  my $le = $gs->{lastEvent};
  return GS_DEFEND             if defined $gs->{defendingInfo} && defined $gs->{defendingInfo}->{playerId};
  return GS_CONQUEST           if $le == LE_THROW_DICE || $le == LE_CONQUER || $le == LE_DEFEND || $le == LE_SELECT_RACE;
  return GS_FINISH_TURN        if $le == LE_DECLINE || $le == LE_SELECT_FRIEND;
  return GS_REDEPLOY           if $le == LE_FAILED_CONQUER && (grep {
      !$_->{currentRegionState}->{inDecline} &&
      ($_->{currentRegionState}->{ownerId} // -1) == $gs->{activePlayerId}
    } @{ $gs->{map}->{regions} });
  return GS_BEFORE_FINISH_TURN if $le == LE_REDEPLOY || $le == LE_FAILED_CONQUER;
  return GS_SELECT_RACE        if (grep {
      (
       !defined $_->{currentTokenBadge} ||
       !defined $_->{currentTokenBadge}->{tokenBadgeId}
      ) && $_->{userId} == $gs->{activePlayerId}
    } @{ $gs->{players} });
  return GS_BEFORE_CONQUEST;
}

sub loadFromDB {
  my $self = shift;
  my %params = (@_);
  my $gameId = $params{id};
  $self->{db} = $params{db};
  my $game = $self->{db}->getGameState($gameId);
  my $map = $self->{db}->getMap($game->{MAPID});

  $self->{_version} = $game->{VERSION};
  $self->{gameState} = {
    gameInfo       => {
      gameId            => $game->{ID},
      gameName          => $game->{NAME},
      gameDescription   => $game->{DESCRIPTION},
      currentPlayersNum => $self->{db}->playersCount($gameId),
      gstate            => $game->{GSTATE},
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
    $self->mergeGameState(eval { decode_json($game->{STATE}) } || {});
  }
  my $connections = $self->{db}->getConnections($gameId);
  foreach my $p ( @{ $self->{gameState}->{players} } ) {
    $p->{inGame} = (grep { $p->{playerId} == $_ } (@$connections));
  }
  if ( $game->{GSTATE} == GST_FINISH ) {
    $self->{gameState}->{state} = GS_IS_OVER;
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

      ownerId          => undef,                  # идентификатор игрока-владельца
      tokenBadgeId     => undef,                  # идентификатор расы игрока-владельца
      tokensNum        => $_->{population} // 0,  # количество фигурок
      conquestIdx      => undef,                  # порядковый номер завоевания (обнуляется по окончанию хода)
      prevTokenBadgeId => undef,
      prevTokensNum    => undef,
      holeInTheGround  => undef,                  # 1 если присутствует нора полуросликов
      lair             => undef,                  # кол-во пещер троллей
      encampment       => undef,                  # кол-во лагерей (какая осень в лагерях...)
      dragon           => undef,                  # 1 если присутствует дракон
      fortiefied       => undef,                  # кол-во фортов
      hero             => undef,                  # 1 если присутствует герой
      inDecline        => undef                   # 1 если раса tokenBadgeId в упадке
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
#      dice               => undef,                # число, которое выпало при броске костей берсерка
      currentTokenBadge  => {
        tokenBadgeId     => undef,
        totalTokensNum   => undef,
        raceName         => undef,
        specialPowerName => undef
      },
      declinedTokenBadge => undef
    } } @$players
  ];

  $self->mergeGameState({
    activePlayerId => scalar(@$players) > 0
                      ? $self->{gameState}->{players}->[0]->{playerId}
                      : undef,
    conquerorId    => undef,
    state          => GS_SELECT_RACE,
    currentTurn    => 0,
    tokenBadges    => $self->initTokenBadges(),
    storage        => $self->initStorage(),
    defendingInfo  => undef,
    prevGenNum     => $game->{GENNUM}
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
      specialPowerName => splice(@sp, int(rand(scalar(@sp))), 1),
      bonusMoney       => 0
    };
  }

  $j = 0;
  while ( @races ) {
    $result[$j++]->{raceName} = splice(@races, int(rand(scalar(@races))), 1);
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
  $self->dropObjects();
  my $gs = { %{ $self->{gameState} } };
  delete $gs->{gameInfo};
  $self->{db}->saveGameState(encode_json($gs), $gs->{activePlayerId}, $gs->{currentTurn}, $self->{gameState}->{gameInfo}->{gameId});
  $self->{_version}++;
}

# вместо созданных объектов игроков и регионов ставим обратно хэши
sub dropObjects {
  my $self = shift;
  # вместо того, чтобы сохранять в json объекты-игроков, сохраняем только
  # информацию о них
  grep { $_ = { %$_ } if UNIVERSAL::can($_, 'can') } @{ $self->players };
  delete $_->{game} for @{ $self->players };
  grep { $_ = { %$_ } if UNIVERSAL::can($_, 'can') } @{ $self->regions };
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
    ? { %{$_[1]} }
    : undef;
}

sub getLastEvent {
  my ($self, $st) = @_;
  return $st if $st == GST_WAIT || $st == GST_BEGIN || $st == GST_EMPTY;
  my $cmd = decode_json($self->{db}->getLastCmd($self->{gameState}->{gameInfo}->{gameId}));
  return LE_FAILED_CONQUER if $cmd->{action} eq 'conquer' && defined $cmd->{dice};
  return {
    decline       => LE_DECLINE,
    selectRace    => LE_SELECT_RACE,
    throwDice     => LE_THROW_DICE,
    conquer       => LE_CONQUER,
    dragonAttack  => LE_CONQUER,
    enchant       => LE_CONQUER,
    defend        => LE_DEFEND,
    redeploy      => LE_REDEPLOY,
    selectFriend  => LE_SELECT_FRIEND,
    finishTurn    => LE_FINISH_TURN
  }->{$cmd->{action}};
}

# возвращает состояние игры для конкретного игрока (удаляет секретные данные)
sub getGameStateForPlayer {
  my $self = shift;
  my $gs = { %{ $self->{gameState} } };
  $gs->{visibleTokenBadges} = [ @{ $gs->{tokenBadges} }[0..5] ];
  my $result = {
    gameId             => $gs->{gameInfo}->{gameId},
    gameName           => $gs->{gameInfo}->{gameName},
    gameDescription    => $gs->{gameInfo}->{gameDescription},
    currentPlayersNum  => $gs->{gameInfo}->{currentPlayersNum},
    activePlayerId     => defined $gs->{conquerorId} ? $gs->{conquerorId} : $gs->{activePlayerId},
    state              => $gs->{gameInfo}->{gstate},
    stage              => $gs->{state},
    defendingInfo      => $gs->{defendingInfo},
    currentTurn        => $gs->{currentTurn},
    map                => { %{ $gs->{map} } },
    visibleTokenBadges => $gs->{visibleTokenBadges},
    friendInfo         => $gs->{friendInfo},
    stoutStatistics    => $gs->{stoutStatistics},
    berserkDice        => $gs->{berserkDice},
    dragonAttacked     => $self->bool($gs->{dragonAttacked}),
    enchanted          => $self->bool($gs->{enchanted}),
    holesPlaced        => $gs->{holesPlaced},
    gotWealthy         => $self->bool($gs->{gotWealthy})
  };
  $result->{lastEvent} = $self->getLastEvent($result->{state});
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
      inGame             => $self->bool($_->{inGame}),
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
  my ($self, %p) = @_;
  if ( !defined $p{player} ) {
    if ( defined $p{sid} ) {
      $p{id} = $self->{db}->getPlayerId($p{sid});
    }
    elsif ( !defined $p{id} ) {
      $p{id} = $self->{gameState}->{activePlayerId};
    }

    # находим в массиве игроков текущего игрока
    foreach ( @{ $self->{gameState}->{players} } ) {
      if ( $_->{playerId} == $p{id} ) {
        $p{player} = $_;
        last;
      }
    }
  }
  return if !$p{player};
  # если объект-игрока уже создан, то возвращаем его
  return $p{player} if UNIVERSAL::can($p{player}, 'can');
  # иначе создаем новый экземпляр
  return SmallWorld::Player->new(self => $p{player}, game => $self);
}

# возвращает регион из массива регионов по id
sub getRegion {
  my ($self, %p) = @_;
  if ( !defined $p{region} && defined $p{id} ) {
    foreach ( @{ $self->{gameState}->{regions} } ) {
      if ( $_->{regionId} == $p{id} ) {
        $p{region} = $_;
        last;
      }
    }
  }
  return if !$p{region};
  # если объект-регион уже создан, то возвращаем его
  return $p{region} if UNIVERSAL::can($p{region}, 'can');
  # иначе создаем новый экземпляр
  return SmallWorld::Region->new(self => $p{region});
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

# возвращает следующий порядковый номер завоевания регионов
sub nextConquestIdx {
  my $result = -1;
  grep { $result = max( $result, ($_->{conquestIdx} // -1) ) } @{ $_[0]->{gameState}->{regions} };
  return $result + 1;
}

# бросаем кубик (возвращает число от 0 до 3) (кубик имеет три нулевых грани и
# три грани 1,2,3)
sub random {
  my $self = shift;
  return (defined $_[0] ? ($_[0]->{dice} // 0) : 0) if $ENV{DEBUG_DICE};
  swLog(LOG_FILE, $self->{gameState}->{prevGenNum});
  $self->{gameState}->{prevGenNum} = (RAND_A * $self->{gameState}->{prevGenNum}) % RAND_M;
  swLog(LOG_FILE, $self->{gameState}->{prevGenNum});
  my $result = $self->{gameState}->{prevGenNum} % 6;
  return $result > 3 ? 0 : $result;
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

sub getDefendNum {
  my ($self, $player, $region, $race, $sp) = @_;
  return max(1, $region->getDefendTokensNum() -
      $sp->conquestRegionTokensBonus($region) - $race->conquestRegionTokensBonus($player, $region, $self->regions, $sp));
}

# возвращает хватает ли игроку фигурок для атаки региона (бросает кубик, если надо)
sub canAttack {
  my ($self, $player, $region, $race, $sp, $result) = @_;
  my $regions = $self->{gameState}->{regions};

  $self->{defendNum} = $self->getDefendNum($player, $region, $race, $sp);

  if ( !defined $self->{gameState}->{berserkDice} && ($self->{defendNum} - $player->{tokensInHand}) ~~ [1..3] ) {
    # не хватает не больше 3 фигурок у игрока, поэтому бросаем кости, если еще не кинули(berserk)
    $player->{dice} = $self->random($result);
    $result->{dice} = $player->{dice};
  }

  # если игроку не хватает фигурок даже с подкреплением, это его последнее завоевание
  if ( $player->{tokensInHand} + $player->safe('dice') < $self->{defendNum} ) {
    if ( (defined $player->{dice} || defined $self->{gameState}->{berserkDice}) && !$result->{readOnly} ) {
      $player->{dice} = undef;
      $self->{gameState}->{berserkDice} = undef;
      $self->gotoRedeploy();
      $self->{gameState}->{state} = GS_BEFORE_FINISH_TURN if !(grep { $player->activeConq($_) } @$regions);
    }
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
  my $region = $self->getRegion(id => $regionId);
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);

  if ( defined $region->{ownerId} ) {
    $defender = $self->getPlayer( id => $region->{ownerId} );
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

sub baseDecline {
  my ($self, $player) = @_;
  my $regions = $self->{gameState}->{regions};
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);
  my $dsp = $self->createSpecialPower('declinedTokenBadge', $player);
  my $drace = $self->createRace($player->{declinedTokenBadge});

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
}

sub decline {
  my $self = shift;
  my $player = $self->getPlayer();

  if ($self->{gameState}->{state} eq GS_BEFORE_FINISH_TURN) {
    $self->{gameState}->{stoutStatistics} = [];
    $self->getPlayerBonus($player, $self->{gameState}->{stoutStatistics});
  }
  $self->baseDecline($player);
  $self->{gameState}->{state} = GS_FINISH_TURN;
}

sub forceDecline {
  my ($self, $playerId) = @_;
  my $player = $self->getPlayer( id => $playerId );
  if ( $playerId == $self->{gameState}->{activePlayerId} ) {
    if ( $self->{gameState}->{state} eq GS_DEFEND ) {
      $self->endDefend();
    }
    else {
      my $dummy = {};
      $self->finishTurn($dummy);
    }
  }
  $self->baseDecline($player);
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
  my ($self, $player, $result) = @_;
  my $regions = $self->regions;
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
    @{ $result->{statistics} } = @{ $self->{gameState}->{stoutStatistics} };
    delete $self->{gameState}->{stoutStatistics};
  } else {
    $result->{statistics} = [];
    $bonus = $self->getPlayerBonus($player, $result->{statistics});
  }
  $player->{coins} += $bonus;

  $sp->finishTurn($self->{gameState});
  $race->finishTurn($self->{gameState});
  @{ $self->{gameState}->{friendInfo} }{qw(friendId)} = () if $player->isFriend();

  @{$_}{qw (conquestIdx prevTokenBadgeId prevTokensNum)} = () for @{ $self->{gameState}->{regions} };

  my $prevPriority = $player->{priority};
  do {
    $self->{gameState}->{activePlayerId} = $self->{gameState}->{players}->[
      ($player->{priority} + 1) % scalar(@{ $self->{gameState}->{players} }) ]->{playerId};
    $player = $self->getPlayer();
  } while !$player->{inGame};

  if ( $player->{priority} < $prevPriority ) {
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

sub gotoRedeploy {
  my ($self) = @_;
  return if $self->{gameState}->{state} eq GS_REDEPLOY;
  $self->{gameState}->{state} = GS_REDEPLOY;
  my $player = $self->getPlayer();
  my $race = $self->createRace($player->{currentTokenBadge});
  $player->{tokensInHand} += $race->redeployTokensBonus($player);
}

sub redeploy {
  my ($self, $regs, $encampments, $fortified, $heroes) = @_;
  my $player = $self->getPlayer();
  my $race = $self->createRace($player->{currentTokenBadge});
  my $sp = $self->createSpecialPower('currentTokenBadge', $player);
  my $lastRegion = defined $regs->[-1] ? $self->getRegion(id => $regs->[-1]->{regionId}): undef;

  $self->gotoRedeploy();
  foreach ( @{ $race->{regions} } ) {
    $player->{tokensInHand} += $_->{tokensNum};
    @ {$_}{qw (tokensNum encampment hero) } = (0, undef, undef);
  }
  foreach ( @{ $regs } ) {
    $self->getRegion(id => $_->{regionId})->{tokensNum} = $_->{tokensNum};
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
    $self->getRegion(id => $_->{regionId})->{encampment} = $_->{encampmentsNum};
  }

  if ( defined $fortified && defined $fortified->{regionId} ) {
    $self->getRegion(id => $fortified->{regionId})->{fortified} = 1;
  }

  foreach ( @{ $heroes } ) {
    $self->getRegion(id => $_->{regionId})->{hero} = 1;
  }
  $self->{gameState}->{state} = GS_BEFORE_FINISH_TURN;
}

sub defend {
  my ($self, $regs) = @_;
  my $player = $self->getPlayer();
  $player->{tokensInHand} = 0;
  foreach ( @{ $regs } ) {
    $self->getRegion(id => $_->{regionId})->{tokensNum} += $_->{tokensNum};
  }
  $self->endDefend();
}

sub endDefend {
  my $self = shift;
  $self->{gameState}->{activePlayerId} = $self->{gameState}->{conquerorId};
  @{ $self->{gameState} }{qw(defendingInfo conquerorId)} = ();
  $self->{gameState}->{state} = GS_CONQUEST;
}

sub enchant {
  my ($self, $regionId) = @_;
  my $player = $self->getPlayer();

  @{ $self->getRegion(id => $regionId) }{qw( ownerId tokenBadgeId conquestIdx )} = (
      $player->{playerId}, $player->{currentTokenBadge}->{tokenBadgeId}, $self->nextConquestIdx() );
  $self->{gameState}->{storage}->{&RACE_SORCERERS} -= 1;
  $self->{gameState}->{enchanted} = 1;
  $self->{gameState}->{state} = GS_CONQUEST if $self->{gameState}->{state} eq GS_BEFORE_CONQUEST;
}

sub selectFriend {
  my ($self, $friendId) = @_;
  $self->{gameState}->{friendInfo}->{friendId} = $friendId;
  $self->{gameState}->{state} = GS_FINISH_TURN;
}

sub dragonAttack {
  my ($self, $regionId) = @_;
  foreach ( @{ $self->{gameState}->{regions} } ) {
    $_->{dragon} = undef;
  }
  my $region = $self->getRegion(id => $regionId);
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

sub id             { return $_[0]->{gameState}->{gameInfo}->{gameId};                  }
sub name           { return $_[0]->{gameState}->{gameInfo}->{gameName};                }
sub stage          { return $_[0]->{gameState}->{state};                               }
sub state          { return $_[0]->{gameState}->{gameInfo}->{gstate};                  }
sub activePlayerId { return $_[0]->{gameState}->{activePlayerId};                      }
sub defendingInfo  { return $_[0]->{gameState}->{defendingInfo};                       }
sub players        { return $_[0]->{gameState}->{players};                             }
sub tokenBadges    { return $_[0]->{gameState}->{tokenBadges};                         }
sub currentTurn    { return $_[0]->{gameState}->{currentTurn};                         }
sub maxTurnNum     { return $_[0]->{gameState}->{map}->{turnsNum} - 1;                 }
sub conqueror      { return $_[0]->getPlayer(id => $_[0]->{gameState}->{conquerorId}); }
sub regions {
  my ($self, $b, $e) = @_;
  my $regions = $self->{gameState}->{regions};
  return $regions if !defined $b || !defined $e;
  my $findB = 0;
  my $findE = 0;
  my $findFirstB = 0;
  my %buf = ();
  foreach ( @$regions ) {
    $findB = $findB || $_->{regionId} == $b->{regionId};
    $findFirstB = $findFirstB || $findB && !$findE;
    $buf{ $_->{regionId} } = $findB ^ $findE;
    $findE = $findE || $_->{regionId} == $e->{regionId};
  }
  my $result = {};
  foreach my $k ( keys %buf ) {
    if ( $buf{$k} == $findFirstB ) {
      foreach ( @$regions ) {
        next unless $_->{regionId} == $k;
        push @$result, $_;
        last;
      }
    }
  }
  return $result;
}
sub berserkDice {
  my $self = shift;
  $self->{gameState}->{berserkDice} = $_[0] if scalar(@_) == 1;
  return $self->{gameState}->{berserkDice};
}

1;

__END__
