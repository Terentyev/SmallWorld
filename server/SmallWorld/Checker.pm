package SmallWorld::Checker;


use strict;
use warnings;
use utf8;

use SmallWorld::Consts;
use SmallWorld::Config;
use SmallWorld::DB;

require Exporter;
sub BEGIN {
  our @ISA    = qw( Exporter );
  our @export_list;

  my $filename = __FILE__;
  open ME, "<$filename" or die "Can't open $filename for input: $!";
  my @lines = <ME>;
  foreach ( @lines ) {
    if ( m/^sub\s+([a-z][A-Za-z_]+)\s+/x ) {
      push @export_list, $1;
    }
  }

  our @EXPORT = @export_list;
}

sub errorCode {
  my ($self, $paramInfo) = @_;
  return $paramInfo->{errorCode} || R_BAD_JSON;
}

sub checkLoginAndPassword {
  my $self = shift;
  return !defined $self->{db}->query('SELECT 1 FROM PLAYERS WHERE username = ? and pass = ?',
                                     @{$self->{json}}{qw/username password/} );
}

sub checkInGame {
  my $self = shift;
  my $gameId = $self->{db}->query('SELECT c.gameId FROM PLAYERS p INNER JOIN CONNECTIONS c 
                                   ON p.id = c.playerId WHERE p.sid = ?', $self->{json}->{sid});
  return defined $gameId;
}

sub checkPlayersNum {
  my $self = shift;
  my $n = $self->{db}->getMaxPlayers($self->{json}->{gameId});
  return $self->{db}->playersCount($self->{json}->{gameId}) >= $n;
}

sub checkIsStarted {
  my ($self, $h) = @_;
  my $gameId = exists($h->{gameId}) ? $h->{gameId} : $self->{db}->getGameId($h->{sid});
  $self->{db}->getGameIsStarted($gameId);
}

sub checkRegions {
  my $self = shift;
  my $s = 0;
  my $r = $self->{json}->{regions};
  my $l = @$r;
  my $ex;
  for (my $i = 0; $i < $l; ++$i){
    if (exists @$r[$i]->{population}) {
      return 1 if @$r[$i]->{population} !~ /^[+-]?\d+\z/ || @$r[$i]->{population} < 0 || @$r[$i]->{population} > 1;
      $s += @$r[$i]->{population};
    }
    return 1 if defined @$r[$i]->{landDescription} && ref @$r[$i]->{landDescription} ne 'ARRAY';
    foreach my $j (@{@$r[$i]->{landDescription}}) {
      $ex = 0;
      foreach (@{&REGION_TYPES}) {
        if ($_ eq $j) {
          $ex = 1;
          last;
        }
      }
      return 1 if !$ex;
    }
    return 1 if !defined @$r[$i]->{adjacent} || ref @$r[$i]->{adjacent} ne 'ARRAY';
    foreach my $j (@{@$r[$i]->{adjacent}}) {

      return 1 if !defined @$r[$j-1]->{adjacent} || ref @$r[$j-1]->{adjacent} ne 'ARRAY';
      #регион граничет с недопустимым регионом или самим собой
      return 1 if $j< 1 || $j > $l || $j == $i + 1;

      #регион A граничет с регионом B, а регион B не граничет с A
      $ex = 0;
      foreach (@{@$r[$j-1]->{adjacent}}) {
        if ($_ == $i + 1) {
          $ex = 1;
          last;
        }
      }
      return 1 if !$ex;
    }
  }
  return $s > LOSTTRIBES_TOKENS_MAX;
}

sub getGameVariables {
  my $self = shift;
  my $js = $self->{json};
  my $game = SmallWorld::Game->new($js->{sid});
  my $player = $game->getPlayer();
  my $region = defined $js->{regionId}
    ? $game->getRegion($js->{regionId})
    : undef;
  my $race = $game->createRace($player->{currentTokenBadge}->{raceName});
  my $sp = $game->createSpecialPower('currentTokenBadge', $player);

  return [$game, $player, $race, $sp];
}

sub checkErrorHandlers {
  my ($self, $errorHandlers) = @_;
  my $errorList = CMD_ERRORS->{ $self->{json}->{action} };

  foreach ( @$errorList ) {
    return $_ if $errorHandlers->{$_}->();
  }

  return R_ALL_OK;
}

sub checkJsonCmd {
  my ($self) = @_;
  my $json = $self->{json};
  my $cmd = $json->{action};
  return R_BAD_JSON if !defined $cmd;

  my $pattern = PATTERN->{$cmd};
  return R_BAD_ACTION if !$pattern;
  foreach ( @$pattern ) {
    my $val = $json->{ $_->{name} };
    # если это необязательное поле и оно пустое, то пропускаем его
    if ( !$_->{mandatory} && !defined $val ) {
      next;
    }

    # если это обязательное поле и оно пустое, то ошибка
    return $self->errorCode($_) if ( !defined $val );

    # если тип параметра -- строка
    if ( $_->{type} eq 'unicode' ) {
      # если длина строки не удовлетворяет требованиям, то ошибка
      return $self->errorCode($_) if ref(\$val) ne 'SCALAR';
      if ( defined $_->{min} && length $val < $_->{min} ||
          defined $_->{max} && length $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
    elsif ( $_->{type} eq 'int' ) {
      # если число, передаваемое в параметре не удовлетворяет требованиям, то ошибка
      return $self->errorCode($_) if ref(\$val) ne 'SCALAR' || $val !~ /^[+-]?\d+\z/;
      if ( defined $_->{min} && $val < $_->{min} ||
          defined $_->{max} && $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
    elsif ( $_->{type} eq 'list' ) {
      return $self->errorCode($_) if ref($val) ne 'ARRAY';
    }

  }

  my $res = $self->checkErrorHandlers({
    &R_ALREADY_IN_GAME              => sub { $self->checkInGame(); },
    &R_BAD_GAME_ID                  => sub { !$self->{db}->dbExists('games', 'id', $self->{json}->{gameId}); },
    &R_BAD_GAME_STATE               => sub { $self->checkIsStarted($self->{json}); },
    &R_BAD_LOGIN                    => sub { $self->checkLoginAndPassword(); },
    &R_BAD_MAP_ID                   => sub { !$self->{db}->dbExists("maps", "id", $self->{json}->{mapId}); },
    &R_BAD_PASSWORD                 => sub { $self->{json}->{password} !~ m/^.{6,18}$/; },
    &R_BAD_REGIONS                  => sub { $self->checkRegions(); },
    &R_BAD_SID                      => sub { defined $self->{json}->{sid} && !$self->{db}->dbExists("players", "sid", $self->{json}->{sid}); },
    &R_BAD_USERNAME                 => sub { $self->{json}->{username} !~ m/^[A-Za-z][\w\-]*$/; },
    &R_GAME_NAME_TAKEN              => sub { $self->{db}->dbExists('games', 'name', $self->{json}->{gameName}); },
    &R_MAP_NAME_TAKEN               => sub { $self->{db}->dbExists('maps', 'name', $self->{json}->{mapName}); },
    &R_NOT_IN_GAME                  => sub { !defined $self->{db}->getGameId($self->{json}->{sid}); },
    &R_TOO_MANY_PLAYERS             => sub { $self->checkPlayersNum(); },
    &R_USERNAME_TAKEN               => sub { $self->{db}->dbExists("players", "username", $self->{json}->{username}); },
  });

  return $res if $res ne R_ALL_OK;
  return $self->checkGameCommand()
    if grep { $_ eq $cmd } qw( defend selectRace conquer throwDice dragonAttack enchant redeploy selectFriend finishTurn );
  return R_ALL_OK;
}

sub checkRegionId {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $js = $self->{json};
  my $regionsInCmd = $js->{regions};
  my $regions = $game->{gameState}->{regions};

  if ( defined $js->{regionId} ) {
    return !grep { $_->{regionId} == $js->{regionId} } @{ $regions };
  }

  if ( defined $js->{regions} ) {
    foreach my $reg ( @{ $js->{regions} } ) {
      return 1 if !grep { $reg->{regionId} == $_->{regionId} } @{ $regions };
    }
  }

  if ( defined $js->{encampments} ) {
    foreach my $reg ( @{ $js->{encampments} } ) {
      return 1 if !grep { $reg->{regionId} == $_->{regionId} } @{ $regions };
    }
  }

  if ( defined $js->{fortified} ) {
    return 1 if !grep { $_->{regionId} == $js->{fortified}->{regionId} } @{ $regions };
  }

  if ( defined $js->{heroes} ) {
    foreach my $reg ( @{ $js->{heroes} } ) {
      return 1 if !grep { $reg == $_->{regionId} } @{ $regions };
    }
  }

  return 0;
}

sub checkRegion {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $js = $self->{json};
  my $races = $game->{gameState}->{regions};

  my $func = $self->can("checkRegion_$js->{action}"); # see UNIVERSAL::can
  return !defined $func || &$func(@_);
}

sub checkRegion_defend {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $regions = $game->{gameState}->{regions};
  my $lostRegion = undef;
  my $lastIdx = 0;
  foreach ( @{ $regions } ) {
    if ( $lastIdx >= $_->{conquestIdx} ) {
      $lostRegion = $_;
    }
  }

  # 1. ставить можно только на регион своей активной расы
  return 1 if $region->{currentTokenBadge}->{tokenBadgeId} != $player->{currentTokenBadge}->{tokenBadgeId};

  # если мы перемещаем войска на смежный с потерянным регионом
  if ( grep { $_ == $region->{regionId} } @{ $lostRegion->{adjacentRegions} } ) {
    # надо убедиться, что несмежных нет, иначе ошибка
    foreach ( @{ $regions } ) {
      my $regionId = $_->{regionId};
      return 1 if $_->{currentTokenBadge}->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} &&
        !grep { $_ == $regionId  } @{ $_->{adjacentRegions} };
    }
  }
  return 0;
}

sub checkRegion_conquer {
  my ($self, $game, $player, $region, $race, $sp) = @_;

  # 1. свои регионы с активной расой захватывать нельзя
  # 2. на первом завоевании можно захватывать далеко не все регионы
  # 3. и вообще есть куча правил нападения на регионы (если это не первое нападение)
  # 4. у игрока на руках должна быть хотя бы одна фигурка
  return 1 if $region->{currentTokenBadge}->{tokenBadgeId} != $player->{currentTokenBadge}->{tokenBadgeId} ||
    $game->isFirstConquer() && !$race->canFirstConquer($region) ||
    !$sp->canAttack($player, $region, $game->{gameState}->{regions});
}

sub checkRegion_dragonAttack {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  return $player->{currentTokenBadge}->{tokenBadgeId} == $region->{currentTokenBadge}->{tokenBadgeId};
}

sub checkRegion_enchant {
  my ($self, $game, $player, $region, $race, $sp) = @_;

  # 1. это должен быть не наш регион
  # 2. регион с активной расой
  # 3. количество фигурок должно быть == 1
  return $player->{currentTokenBadge}->{tokenBadgeId} == $region->{currentTokenBadge}->{tokenBadgeId} ||
    $region->{inDeclune} ||
    $region->{tokensNum} == 1;
}

sub checkRegion_redeploy {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $js = $self->{json};

  # ставить войска/лагеря/форты/героев можно только на свои регионы
  foreach my $reg ( (@{ $js->{regions} }, @{ $js->{encampments} }, $js->{fortified}, map { regionId => $_ }, @{ $js->{heroes} }) ) {
    return 1 if grep {
      $_->{regionId} == $reg->{regionId} && $_->{ownerId} != $player->{playerId}
    } @{ $game->{regions} };
  }
}

sub checkRegionIsImmune {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $js = $self->{json};

  # а вдруг у территории иммунитет?
  return $game->isImmuneRegion($region);
}

sub checkStage {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $js = $self->{json};

  my %states = {
    &GS_DEFEND      => [ "defend" ],
    &GS_SELECT_RACE => [ "selectRace" ],
    &GS_CONQUEST    => [ "conquer", "throwDice", "dragonAttack", "enchant", "redeploy", "selectFriend", "finishTurn" ],
    &GS_REDEPLOY    => [ "redeploy", "selectFriend", "finishTurn" ],
    &GS_FINISH_TURN => [ "finishTurn" ]
  };

  # 1. пользователь, который послал команду, != активный пользователь
  # 2. действие, которое запрашивает пользователь, не соответствует текущему
  #    состоянию игры
  my $func = $self->can("checkStage_$js->{action}"); # see UNIVERSAL::can
  return $self->{db}->getPlayerId($js->{sid}) != $game->{gameState}->{activePlayerId} ||
    !grep { $_ eq $js->{action} } @{ $states{ $game->{gameState}->{state} } } ||
    !$sp->canCmd($js, $player->{tokensInHand});
}

sub checkEnoughTokens {
  my ($game, $player) = $_[0]->getGameVariables();
  my $tokensNum = 0;
  grep { $tokensNum += $_->{tokensNum} } @{ $_[0]->{json}->{regions} };
  return $tokensNum > $player->{tokensInHand};
}

sub checkTokensInHand {
  my ($game, $player) = $_[0]->getGameVariables();
  my $tokensNum = 0;
  grep { $tokensNum += $_->{tokensNum} } @{ $_[0]->{json}->{regions} };
  return $tokensNum < $player->{tokensInHand};
}

sub checkTokensNum {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  # только для redeploy
  my $tokensNum = $player->{tokensInHand};
  grep { $tokensNum += $_->{tokensNum} } @{ $game->{gameState}->{regions} };
  grep { $tokensNum -= $_->{tokensNum} } @{ $self->{json}->{regions} };
  return $tokensNum;
}

sub checkForts {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  return defined $self->{json}->{fortified} && defined $self->{json}->{fortified}->{regionId} &&
    FORTRESS_MAX >= 1 * grep { defined $_->{fortified} } @{ $game->{gameState}->{regions} };
}

sub checkFortsInRegion {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  # можно ставить только один форт в регион
  return grep {
    $_->{regionId} == $self->{json}->{fortified}->{regionId} && defined $_->{fortified}
  } @{ $game->{gameState}->{regions} };
}

sub checkEnoughEncamps {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  my $encampsNum = 0;
  grep { $encampsNum += $_->{encampment} } @{ $game->{gameState}->{regions} };
  grep { $encampsNum += $_->{encampmentsNum} } @{ $self->{json}->{encampments} };
  return $encampsNum > ENCAMPMENTS_MAX;
}

sub checkFriend {
  my ($self, $game, $player, $region, $race, $sp) = @_;
  # мы не можем подружиться с тем, на регион с активной расой которого нападали
  # в этом ходу
  return grep {
    defined $_->{conquestIdx} && $_->{ownerId} == $self->{json}->{friendId} && !defined $_->{inDecline}
  } @{ $game->{gameState}->{regions} };
}

sub checkGameCommand {
  my ($self) = @_;
  my $js = $self->{json};
  my $cmd = $js->{action};
  my @gameVariables = $self->getGameVariables();
  my ($game, $player, $region, $race, $sp) = @gameVariables;
  my $regions = $game->{gameState}->{regions};

  my $errorHandlers = {
    &R_BAD_ATTACKED_RACE            => sub { $player->{playerId} == $region->{ownerId}; },
    &R_BAD_FRIEND                   => sub { $self->checkFriend(@gameVariables); },
    &R_BAD_FRIEND_ID                => sub { !grep { $_->{playerId} == $js->{friendId} && $_->{playerId} != $player->{playerId} } @{ $game->{gameState}->{players} }; },
    &R_BAD_MONEY_AMOUNT             => sub { $player->{coins} < $js->{position}; },
    &R_BAD_REGION                   => sub { $self->checkRegion(@gameVariables); },
    &R_BAD_REGION_ID                => sub { $self->checkRegionId(@gameVariables); },
    &R_BAD_SET_HERO_CMD             => sub { HEROES_MAX < $@{ $js->{heroes} }; },
    &R_BAD_SID                      => sub { $self->{db}->getPlayerId($js->{sid}) != $game->{activePlayerId}; },
    &R_BAD_STAGE                    => sub { $self->checkStage(@gameVariables); },
    &R_BAD_TOKENS_NUM               => sub { $self->checkTokensNum(@gameVariables); },
    &R_CANNOT_ENCHANT               => sub { $region->{inDecline}; },
    &R_NO_MORE_TOKENS_IN_STORAGE    => sub { $game->tokensInStorage(RACE_SORCERERS) == 0; },
    &R_NOT_ENOUGH_ENCAMPS           => sub { $self->checkEnoughEncamps(@gameVariables); },
    &R_NOT_ENOUGH_TOKENS            => sub { $self->checkEnoughTokens(@gameVariables); },
    &R_NOTHING_TO_ENCHANT           => sub { $region->{tokensNum} == 0; },
    &R_REGION_IS_IMMUNE             => sub { $self->checkRegionIsImmune(@gameVariables); },
    &R_THERE_ARE_TOKENS_IN_THE_HAND => sub { $self->checkTokensInHand(@gameVariables); },
    &R_TOO_MANY_FORTS               => sub { $self->checkForts(@gameVariables); },
    &R_TOO_MANY_FORTS_IN_REGION     => sub { $self->checkFortsInRegion(@gameVariables); },
    &R_USER_HAS_NO_REGIONS          => sub { !grep { $_->{currentTokenBadge}->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} } @{ $regions }; },
  };

  my $errorList = CMD_ERRORS->{$cmd};
  foreach ( @$errorList ) {
    return $_ if $errorHandlers->{$_}->();
  }
  return R_ALL_OK;
}

1;

__END__
