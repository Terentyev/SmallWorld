package SmallWorld::Checker;


use strict;
use warnings;
use utf8;
use List::Util qw( min max);

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
  my ($self, $js) = @_;
  return !defined $self->{db}->fetch1('SELECT 1 FROM PLAYERS WHERE username = ? and pass = ?',
                                     @{ $js }{qw/username password/} );
}

sub checkInGame {
  my ($self, $js) = @_;
  my $gameId = $self->{db}->fetch1('SELECT c.gameId FROM PLAYERS p INNER JOIN CONNECTIONS c 
                                   ON p.id = c.playerId WHERE p.sid = ?', $js->{sid});
  return defined $gameId;
}

sub checkPlayersNum {
  my ($self, $js) = @_;
  my $n = $self->{db}->getMaxPlayers($js->{gameId}) - $self->{db}->getAINum($js->{gameId});
  return $self->{db}->realPlayersCount($js->{gameId}) >= $n;
}

sub checkGameState {
  my ($self, $h) = @_;
  return 0 if $h->{action} eq 'getGameState';

  my $gameId = exists($h->{gameId}) ? $h->{gameId} : $self->{db}->getGameId($h->{sid});
  my %gst = (
    &GST_WAIT    => ['setReadinessStatus', 'aiJoin', 'joinGame', 'leaveGame', 'saveGame'],
    &GST_BEGIN   => ['saveGame', 'leaveGame', @{ &GAME_COMMANDS }],
    &GST_IN_GAME => ['saveGame', 'leaveGame', @{ &GAME_COMMANDS }],
    &GST_FINISH  => ['saveGame', 'leaveGame'],
    &GST_EMPTY   => []
  );
  foreach ( @{ $gst{$self->{db}->getGameStateOnly($gameId)} } ) {
    return 0 if $_ eq $h->{action};
  }
  return 1;
}

sub checkRegions {
  my ($self, $js) = @_;
  my $s = 0;
  my $r = $js->{regions};
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

      return 1 if scalar(@$r) < $j || !defined @$r[$j-1]->{adjacent} || ref @$r[$j-1]->{adjacent} ne 'ARRAY';
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

sub checkActions {
  my ($self, $js) = @_;
  foreach my $act ( @{ $js->{actions} } ) {
    return 1 if
      !defined $act or !defined $act->{action} ||
      !(grep { $_ eq $act->{action} } @{ &SAVED_COMMANDS });
  }
  return 0;
}

sub checkUsersLoggedIn {
  my ($self, $js) = @_;
  foreach ( @{ $js->{actions} } ) {
    return 1 if defined $_->{userId} && !defined $self->{db}->getSid($_->{userId});
  }
  return 0;
}

sub checkErrorHandlers {
  my ($self, $js, $errorHandlers) = @_;
  my $errorList = CMD_ERRORS->{ $js->{action} };

  foreach ( @$errorList ) {
    return $_ if exists $errorHandlers->{$_} && $errorHandlers->{$_}->();
  }

  return R_ALL_OK;
}

sub checkJsonCmd {
  my ($self, $js, $result) = @_;
  my $cmd = $js->{action};
  if ( !defined $cmd ) {
    $result->{result} = R_BAD_JSON;
    return;
  }

  my $pattern = PATTERN->{$cmd};
  if ( !$pattern ) {
    $result->{result} = R_BAD_ACTION;
    return;
  }
  foreach ( @$pattern ) {
    my $val = $js->{ $_->{name} };
    # если это необязательное поле и оно пустое, то пропускаем его
    if ( !$_->{mandatory} && !defined $val ) {
      next;
    }

    # если это обязательное поле и оно пустое, то ошибка
    if ( !defined $val ) {
      $result->{result} = $self->errorCode($_);
      return;
    }

    # если тип параметра -- строка
    if ( $_->{type} eq 'unicode' ) {
      # если длина строки не удовлетворяет требованиям, то ошибка
      if ( ref(\$val) ne 'SCALAR' ) {
        $result->{result} = $self->errorCode($_);
        return;
      }
      if ( defined $_->{min} && length $val < $_->{min} ||
          defined $_->{max} && length $val > $_->{max} ) {
        $result->{result} = $self->errorCode($_);
        return;
      }
    }
    elsif ( $_->{type} eq 'int' ) {
      # если число, передаваемое в параметре не удовлетворяет требованиям, то ошибка
      if ( ref(\$val) ne 'SCALAR' || $val !~ /^[+-]?\d+\z/ ) {
        $result->{result} = $self->errorCode($_);
        return;
      }
      if ( defined $_->{min} && $val < $_->{min} ||
          defined $_->{max} && $val > $_->{max} ) {
        $result->{result} = $self->errorCode($_);
        return;
      }
    }
    elsif ( $_->{type} eq 'list' ) {
      if ( ref($val) ne 'ARRAY' ) {
        $result->{result} = $self->errorCode($_);
        return;
      }
    }
    elsif ( $_->{type} eq 'hash' ) {
      if ( ref($val) ne 'HASH' ) {
        $result->{result} = $self->errorCode($_);
        return;
      }
    }
  }

  $result->{result} = $self->checkErrorHandlers($js, {
    &R_ALREADY_IN_GAME              => sub { $self->checkInGame($js); },
    &R_BAD_AI                       => sub { defined $js->{ai} && $js->{ai} > $self->{db}->getMaxPlayersInMap($js->{mapId}); },
    &R_BAD_GAME_ID                  => sub { !$self->{db}->dbExists('GAMES', 'id', $js->{gameId}); },
    &R_BAD_GAME_STATE               => sub { $self->checkGameState($js); },
    &R_BAD_LOGIN                    => sub { $self->checkLoginAndPassword($js); },
    &R_BAD_MAP_ID                   => sub { !$self->{db}->dbExists("maps", "id", $js->{mapId}); },
    &R_BAD_PASSWORD                 => sub { $js->{password} !~ m/^.{6,18}$/; },
    &R_BAD_REGIONS                  => sub { $self->checkRegions($js); },
    &R_BAD_SID                      => sub { defined $js->{sid} && !$self->{db}->dbExists("players", "sid", $js->{sid}); },
    &R_BAD_USERNAME                 => sub { $js->{username} !~ m/^[A-Za-z][\w\-]*$/; },
    &R_GAME_NAME_TAKEN              => sub { $self->{db}->gameWithNameExists($js->{gameName}); },
    &R_ILLEGAL_ACTION               => sub { $self->checkActions($js); },
    &R_MAP_NAME_TAKEN               => sub { $self->{db}->dbExists('maps', 'name', $js->{mapName}); },
    &R_NOT_IN_GAME                  => sub { !defined $self->{db}->getGameId($js->{sid}); },
    &R_TOO_MANY_PLAYERS             => sub { $self->checkPlayersNum($js); },
    &R_USER_NOT_LOGGED_IN           => sub { $self->checkUsersLoggedIn($js); },
    &R_USERNAME_TAKEN               => sub { $self->{db}->dbExists("players", "username", $js->{username}); },
  });

  if (
      $result->{result} eq R_ALL_OK &&
      (grep { $_ eq $cmd } (@{ &GAME_COMMANDS }))
  ) {
    $self->checkGameCommand($js, $result);
  }
}

sub getGameVariables {
  my ($self, $js) = @_;
  my $game = $self->getGame($js);
  my $player = $game->getPlayer();
  my $region = defined $js->{regionId}
    ? $game->getRegion(id => $js->{regionId})
    : undef;
  my $race = $game->createRace($player->{currentTokenBadge});
  my $sp = $game->createSpecialPower('currentTokenBadge', $player);

  return ($game, $player, $region, $race, $sp);
}

sub existsDuplicates {
  my ($self, $ref) = @_;
  my %h = ();

  foreach ( @$ref ) {
    return 1 if exists $h{$_->{regionId}};
    $h{$_->{regionId}} = 1;
  }
  return 0;
}

sub checkRegionId {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  my $regionsInCmd = $js->{regions};
  my $regions = $game->{gameState}->{regions};

  if ( defined $js->{regionId} ) {
    return !(grep { $_->{regionId} == $js->{regionId} } @{ $regions });
  }

  if ( defined $js->{regions} ) {
    foreach my $reg ( @{ $js->{regions} } ) {
      return 1 if !(grep { defined $reg->{regionId} && $reg->{regionId} == $_->{regionId} } @{ $regions });
    }
  }

  if ( defined $js->{encampments} ) {
    foreach my $reg ( @{ $js->{encampments} } ) {
      return 1 if !(grep { ($reg->{regionId} // -1) == $_->{regionId} } @{ $regions });
    }
  }

  if ( defined $js->{fortified} ) {
      return 1 if !(grep { $_->{regionId} == ($js->{fortified}->{regionId} // -1) } @{ $regions });
  }

  if ( defined $js->{heroes} ) {
    foreach my $reg ( @{ $js->{heroes} } ) {
      return 1 if !(grep { ($reg->{regionId} // -1) == $_->{regionId} } @{ $regions });
    }
  }

  return 0;
}

sub checkRegion {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;
#  my $races = $game->{gameState}->{regions};

  my $func = $self->can("checkRegion_$js->{action}"); # see UNIVERSAL::can
  return !defined $func || &$func(@_);
}

sub checkRegion_defend {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;
  my $regions = $game->{gameState}->{regions};
  my $lostRegion = undef;
  my $lastIdx = -1;
  foreach ( @{$regions} ) {
    if ( defined $_->{conquestIdx} && $lastIdx < $_->{conquestIdx} ) {
      $lastIdx = $_->{conquestIdx};
      $lostRegion = $_;
    }
  }

  my $adj = 0;
  # 1. ставить можно только на регионы своей активной расы
  foreach my $r ( @{$js->{regions}} ) {
    return 1 if !(grep { $r->{regionId} == $_->{regionId} } @{ $race->{regions} });
    $adj = $adj || (grep { $r->{regionId} == $_ } @{ $lostRegion->{adjacentRegions} });
  }

  # если мы перемещаем войска на смежный с потерянным регионом
  if ( $adj ) {
    # надо убедиться, что несмежных нет, иначе ошибка
    foreach ( @{ $regions } ) {
      my $regionId = $_->{regionId};
      return 1 if $player->activeConq($_) &&
        !(grep { $_ == $regionId  } @{ $lostRegion->{adjacentRegions} });
    }
  }
  return 0;
}

sub checkRegion_conquer {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;

  # 1. свои регионы с активной расой захватывать нельзя
  # 2. на первом завоевании можно захватывать только при отдельных условиях
  # 3. у рас и умений есть особые правила нападения на регионы

  my $finfo = $game->{gameState}->{friendInfo};
  return $player->activeConq($region) ||
         $game->isFirstConquer() && !$game->canFirstConquer($region, $race, $sp) ||
         !$game->isFirstConquer() && (
             !$sp->canAttack($region) ||
             !(grep $player->id == $_->ownerId, @{ $sp->getRegionsForAttack($region) })
         ) ||
         (defined $finfo && ($finfo->{diplomatId} // -2) == ($region->{ownerId} // -1) &&
         ($finfo->{friendId} // -1) == $player->{playerId} && !$region->{inDecline});
}

sub checkRegion_dragonAttack {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;
  return checkRegion_conquer(@_);
}

sub checkRegion_enchant {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;

  # 1. это должен регион другого игрока, мы с ним не друзья
  # 2. регион с активной расой, без лагерей
  # 3. количество фигурок должно быть == 1
#  my $finfo = $game->{gameState}->{friendInfo};
#  return $player->activeConq($region) || !defined $region->{ownerId} ||
#         (defined $finfo && $finfo->{diplomatId} == ($region->{ownerId} // -1) && ($finfo->{friendId} // -1) == $player->{playerId}) ||
  return checkRegion_conquer(@_) || !defined $region->{ownerId} ||
         $region->{inDecline} || $region->{encampment} || $region->{tokensNum} != 1;
}

sub checkRegion_redeploy {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;

  # в каждом массиве не должны повторяться регионы
  return 1 if $self->existsDuplicates($js->{regions}) ||
    $self->existsDuplicates($js->{encampments}) ||
    $self->existsDuplicates($js->{heroes});

  # у нас должны быть регионы, чтобы расставлять фигурки
  return 1 if !(grep { $player->activeConq($_) } @{ $game->{gameState}->{regions} });

  # войска можно ставить только на свои территории
  foreach my $reg ( @{ $js->{regions} } ) {
     return 1 if (grep
       $_->{regionId} == $reg->{regionId} && !$player->activeConq($_), @{ $game->{gameState}->{regions} });
  }

  # ставить лагеря/форты/героев можно только на регионы,
  # которые так же указаны в поле regions команды redeploy
  my @tmp = ();
  push @tmp, @{ $js->{encampments} } if defined $js->{encampments};
  push @tmp, $js->{fortified} if defined $js->{fortified};
  push @tmp, @{ $js->{heroes} } if defined $js->{heroes};
  foreach my $reg ( @tmp ) {
    return 1 if defined $reg && !(grep {
      $_->{regionId} == $reg->{regionId} #&& !$player->activeConq($_)
    } @{ $js->{regions} });
  }
}

sub checkStage {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;

  my %states = (
    &GS_DEFEND             => [ 'defend' ],
    &GS_SELECT_RACE        => [ 'selectRace' ],
    &GS_BEFORE_CONQUEST    => [ 'decline', 'conquer', 'throwDice', 'dragonAttack', 'enchant', 'redeploy' ],
    &GS_CONQUEST           => [ 'conquer', 'throwDice', 'dragonAttack', 'enchant', 'redeploy' ],
    &GS_REDEPLOY           => [ 'redeploy' ],
    &GS_BEFORE_FINISH_TURN => [ 'finishTurn', 'selectFriend', 'decline' ],
    &GS_FINISH_TURN        => [ 'finishTurn' ],
    &GS_IS_OVER            => [],
  );

  # 1. пользователь, который послал команду, != активный пользователь
  # 2. действие, которое запрашивает пользователь, не соответствует текущему
  #    состоянию игры
  # 3. попытка завоевания с нулевым числом фигурок на руках
  # 4. команда окончания хода с ненулевым числом фигурок на руках
  # 5. после бросока кубика может идти только команда conquer
  my $state = $game->{gameState}->{state};

  return $self->{db}->getPlayerId($js->{sid}) != $game->{gameState}->{activePlayerId} ||
    !(grep { $_ eq $js->{action} } @{ $states{ $state } }) ||
    ($js->{action} eq 'conquer') && (!defined $player->{tokensInHand} || $player->{tokensInHand} == 0) ||
    !$sp->canCmd($js, $state, $player) || !$race->canCmd($js->{action}, $game->{gameState});
}

sub checkStage_throwDice {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  return $player->{tokensInHand} == 0;
}

sub checkEnoughTokens {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  my $tokensNum = 0;
  $tokensNum += $_->{tokensNum} // 0 for @{ $js->{regions} };
  return $tokensNum > $player->{tokensInHand};
}

sub checkEnoughTokens_redeploy {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  my $tokensNum = $player->{tokensInHand};
  if ( $game->{gameState}->{state} ne GS_REDEPLOY ) {
    $tokensNum += $race->redeployTokensBonus($player);
  }
  $tokensNum += $_->{tokensNum} for @{ $race->{regions} };
  $tokensNum -= $_->{tokensNum} // 0 for @{ $js->{regions} };
  return $tokensNum < 0;
}

sub checkTokensInHand {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  my $tokensNum = 0;
  $tokensNum += $_->{tokensNum} // 0 for @{ $js->{regions} };
  return $tokensNum < $player->{tokensInHand};
}

sub checkTokensNum {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;

  my $func = $self->can("checkTokensNum_$js->{action}"); # see UNIVERSAL::can
  return !defined $func || &$func(@_);
}

sub checkTokensNum_redeploy {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;
  return (grep { !defined $_->{tokensNum} || $_->{tokensNum} < 0 } @{ $js->{regions} }) ||
         (scalar(@{ $js->{regions} }) == 1 && !$js->{regions}->[0]->{tokensNum});
}

sub checkTokensNum_defend {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;
  return (grep { !defined $_->{tokensNum} || $_->{tokensNum} < 0 } @{ $js->{regions} });
}

sub checkTokensNum_conquer {
  my ($self, $js, $game, $player, $region, $race, $sp, $result) = @_;
  return !$game->canAttack($player, $region, $race, $sp, $result);
}

sub checkForts {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  return defined $js->{fortified} && defined $js->{fortified}->{regionId} &&
    FORTRESS_MAX <= 1 * (grep { defined $_->{fortified} } @{ $game->{gameState}->{regions} });
}

sub checkFortsInRegion {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  # можно ставить только один форт в регион
  return $js->{fortified} &&
    (grep {
      $_->{regionId} == $js->{fortified}->{regionId} && defined $_->{fortified}
    } @{ $game->{gameState}->{regions} });
}

sub checkEnoughEncamps {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  my $encampsNum = 0;
  $encampsNum += ($_->{encampmentsNum} // 0) for @{ $js->{encampments} };
  return $encampsNum > ENCAMPMENTS_MAX;
}

sub checkTokensForRedeployment {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  return 0;
#  my $tokensNum = $player->{tokensInHand};
#  $tokensNum += $_->{tokensNum} for @{ $race->{regions} };
#  $tokensNum -= $_->{tokensNum} // 0 for @{ $js->{regions} };
#  return $tokensNum < 0;
}

sub checkFriend {
  my ($self, $js, $game, $player, $region, $race, $sp) = @_;
  # мы не можем подружиться с игроком, если мы нападали на его aктивную расу на этом ходу
  my $tid = $game->getPlayer( id => $js->{friendId} )->{currentTokenBadge}->{tokenBadgeId};
  return $player->{playerId} == $js->{friendId} || grep {
    ($_->{prevTokenBadgeId} // -1 ) == ($tid // -2)
  } @{ $game->{gameState}->{regions} };
}

sub checkGameCommand {
  my ($self, $js, $result) = @_;
  my $cmd = $js->{action};
  my @gameVariables = $self->getGameVariables($js);
  my ($game, $player, $region, $race, $sp) = @gameVariables;
  my $regions = $game->{gameState}->{regions};

  $result->{result} = $self->checkErrorHandlers($js, {
    &R_BAD_ATTACKED_RACE            => sub { $player->{playerId} == ($region->{ownerId} // 0); },
    &R_BAD_ENCAMPMENTS_NUM          => sub { grep { !defined $_->{encampmentsNum} || $_->{encampmentsNum} <= 0 } @{ $js->{encampments} }; },
    &R_BAD_FRIEND                   => sub { $self->checkFriend($js, @gameVariables); },
    &R_BAD_FRIEND_ID                => sub { !(grep { $_->{playerId} == $js->{friendId} } @{ $game->{gameState}->{players} }); },
    &R_BAD_MONEY_AMOUNT             => sub { $player->{coins} < $js->{position}; },
    &R_BAD_REGION                   => sub { $self->checkRegion($js, @gameVariables, $result); },
    &R_BAD_REGION_ID                => sub { $self->checkRegionId($js, @gameVariables); },
    &R_BAD_SET_HERO_CMD             => sub { defined $js->{heroes} && scalar(@{$js->{heroes}}) != min (scalar(@{$js->{regions}}), HEROES_MAX); },
    &R_BAD_SID                      => sub { !$self->{db}->dbExists("players", "sid", $js->{sid});  },
    &R_BAD_STAGE                    => sub { $self->checkStage($js, @gameVariables); },
    &R_BAD_TOKENS_NUM               => sub { $self->checkTokensNum($js, @gameVariables, $result); },
    &R_CANNOT_ENCHANT               => sub { $region->{inDecline}; },
    &R_NO_MORE_TOKENS_IN_STORAGE    => sub { $game->tokensInStorage(RACE_SORCERERS) == 0; },
    &R_NO_TOKENS_FOR_REDEPLOYMENT   => sub { $self->checkTokensForRedeployment($js, @gameVariables); },
    &R_NOT_ENOUGH_ENCAMPS           => sub { $self->checkEnoughEncamps($js, @gameVariables); },
    &R_NOT_ENOUGH_TOKENS            => sub { $self->checkEnoughTokens($js, @gameVariables); },
    &R_NOT_ENOUGH_TOKENS_FOR_R      => sub { $self->checkEnoughTokens_redeploy($js, @gameVariables); },
    &R_NOTHING_TO_ENCHANT           => sub { $region->{tokensNum} == 0; },
    &R_REGION_IS_IMMUNE             => sub { $region->isImmune(); },
    &R_THERE_ARE_TOKENS_IN_THE_HAND => sub { $self->checkTokensInHand($js, @gameVariables); },
    &R_TOO_MANY_FORTS               => sub { $self->checkForts($js, @gameVariables); },
    &R_TOO_MANY_FORTS_IN_REGION     => sub { $self->checkFortsInRegion($js, @gameVariables); },
    &R_USER_HAS_NOT_REGIONS         => sub { !(grep { $player->activeConq($_) } @{ $regions }); },
  });
  $game->save();
}

1;

__END__
