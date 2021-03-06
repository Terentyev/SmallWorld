package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON qw( encode_json decode_json );
use File::Basename qw( basename );

use SW::Util qw(swLog);

use SmallWorld::Consts;
use SmallWorld::Config;
use SmallWorld::DB;
use SmallWorld::Checker;
use SmallWorld::Game;
use SmallWorld::Utils;

sub new {
  my $class = shift;
  my $self = { db => undef, _game => undef, loading => 0 };

  $self->{db} = SmallWorld::DB->new(
      db          => DB_NAME,
      user        => DB_LOGIN,
      passwd      => DB_PASSWORD,
      maxBlobSize => DB_MAX_BLOB_SIZE);

  bless $self, $class;
  return $self;
}

sub process {
  my ($self, $r) = @_;
  if ( !defined $r ) {
    $r = '{}';
  }
  my $js = eval { return decode_json($r) or {}; };

  my $result = $self->checkAndDo($js);
  if ( $ENV{LENA} ) {
    # у Лены sid проверяется только как число, а наш сервер почему-то возвращает
    # строку... Ничего лучше пока не придумано.
    if ( $js->{action} eq 'login' && $result->{result} eq R_ALL_OK ) {
      $result->{sid} *= 1;
    }
  }
  $result = encode_json($result)."\n" or die "Can not encode JSON-object\n";
  debug($r, $result);
  print $result;
  $self->{_game} = undef;
}

sub checkAndDo {
  my ($self, $js) = @_;
  my $result = { result => R_ALL_OK };
  $self->checkJsonCmd($js, $result);

  $self->saveCmd($js, $result, 1) if ($js->{action} // 'createGame') ne 'createGame' && ($js->{action} // 'setReadinessStatus') ne 'setReadinessStatus';
  if ( $result->{result} eq R_ALL_OK ) {
    my $func = $self->can("cmd_$js->{action}");
    &$func($self, $js, $result) if defined $func;
  }
  $self->saveCmd($js, $result) if ($js->{action} // '') eq 'createGame' || ($js->{action} // '') eq 'setReadinessStatus';
  $self->{db}->commit;
  
  return $result;
}

sub debug {
  swLog(LOG_FILE, @_);
}

sub getGame {
  my ($self, $js, $id, $readonly) = @_;
  $id = defined $id
    ? $id
    : (defined $js->{gameId}
        ? $js->{gameId}
        : $self->{db}->getGameId($js->{sid}));

  my $version = $self->{db}->getGameVersion($id);

#  my ($version, $id) = @{ $self->{db}->getGameVersionAndId($js->{gameId}) };
  if ( !defined $self->{_game} ||
      (grep { $_->{isReady} == 0 } @{ $self->{_game}->{gameState}->{players} }) ||
      $self->{_game}->{gameState}->{gameInfo}->{gameId} != $id ||
      $self->{_game}->{_version} != $version ) {
    $self->{_game} = SmallWorld::Game->new(db => $self->{db}, id => $id, readonly => $readonly);
  }
  return $self->{_game};
}

sub needSaveCmd {
  my ($self, $js, $result) = @_;
  if ( $js->{action} eq 'conquer' ) {
    return 1 if defined $result->{dice};
    if ( $result->{result} eq R_BAD_TOKENS_NUM ) {
      return decode_json($self->{db}->getLastCmd($self->{db}->getGameId($js->{sid}))->[0])->{action} eq 'throwDice';
    }
  }
  return 0 if $result->{result} ne R_ALL_OK;
  foreach ( @{ &SAVED_COMMANDS } ) {
    return 1 if $_ eq $js->{action};
  }
  return 0;
}

sub saveCmd {
  my ($self, $js, $result) = @_;
  return if !$self->needSaveCmd($js, $result);

  my $cmd = { %$js };
  my $gameId = $cmd->{gameId};
  if ( $cmd->{action} eq 'createGame' ) {
    # если игра создается этой командой, то id этой игры лушче искать по имени
    # игры, т. к. игрок, который создает эту игру необязательно играет в нее.
    $gameId = $self->{db}->getGameIdByName($cmd->{gameName});
  }
  if ( exists $cmd->{sid} ) {
    $cmd->{userId} = $self->{db}->getPlayerId($cmd->{sid});
    $gameId = $gameId // $self->{db}->getGameId($cmd->{sid});
    delete $cmd->{sid};
  }
  $self->{db}->lockGame($gameId) if $cmd->{action} ne 'createGame';
  if ( $cmd->{action} eq 'setReadinessStatus' ) {
    # если игра началась, то сохраняем в историю сгенерированные пары рас и
    # способностей
    my $game = $self->getGame($js);
    if ( $game->{gameState}->{gameInfo}->{gstate} != GST_WAIT ) {
      $cmd->{visibleRaces} = [];
      foreach ( @{ $game->{gameState}->{tokenBadges} } ) {
        push @{ $cmd->{visibleRaces} }, $_->{raceName} if defined $_->{raceName};
      }
      $cmd->{visibleSpecialPowers} = [];
      push @{ $cmd->{visibleSpecialPowers} }, $_->{specialPowerName} foreach ( @{ $game->{gameState}->{tokenBadges} } );
    }
  }
  if ( $cmd->{action} eq 'conquer' ) {
    my $game = $self->getGame($js);
    if ( defined $result->{dice} || $game->stage ne GS_CONQUEST && $game->stage ne GS_BEFORE_CONQUEST ) {
      $cmd->{dice} = 1;
    }
  }
  $self->{db}->saveCommand($gameId, encode_json($cmd));
  $self->{db}->unlockGame;
}

# возвращает url до картинки с изображением карты
sub getMapUrl {
  my ($self, $mapId) = @_;
  opendir(DIR, MAP_IMGS_DIR);
  my @files = readdir(DIR);
  my $prefix = MAP_IMG_PREFIX;
  my $img = undef;
  foreach my $file ( @files ) {
    if ( basename($file) =~ m/$prefix$mapId\.(png|jpg|jpeg)/ ) {
      return MAP_IMG_URL_PREFIX . basename($file);
    }
  }
  return '';
}

sub getGameInitialGeneratedNum {
  my ($self, $js) = @_;
  return $js->{randseed} if defined $js->{randseed} && $self->{loading};
  return int(rand(RAND_EXPR));
}

# Команды, которые приходят от клиента
sub cmd_resetServer {
  return if !$ENV{DEBUG};
  my ($self, $js, $result) = @_;
  $self->{db}->clear();
}

sub cmd_register {
  my ($self, $js, $result) = @_;
  $self->{db}->addPlayer( @$js{qw/username password/} );
}

sub cmd_login {
  my ($self, $js, $result) = @_;
  $result->{sid} = $self->{db}->makeSid( @$js{qw/username password/} );
  $result->{userId} = $self->{db}->getPlayerId($result->{sid});
}

sub cmd_logout {
  my ($self, $js, $result) = @_;
  $self->{db}->logout($js->{sid});
}

sub cmd_sendMessage {
  my ($self, $js, $result) = @_;
  $self->{db}->addMessage( @$js{qw/sid text/} );
}

sub cmd_getMessages {
  my ($self, $js, $result) = @_;
  my $ref = $self->{db}->getMessages($js->{since});
  my @a = ();
  foreach (@{$ref}) {
    push @a, { 'id' => $_->{ID}, 'text' => $_->{TEXT}, 'username' => $_->{USERNAME}, 'time' => TEST_MODE ? $_->{ID} : $_->{T} };
  }
  @{$result->{messages}} = reverse @a;
}

sub cmd_createDefaultMaps {
  return if !$ENV{DEBUG};
  my ($self, $js, $result) = @_;
  my @maps = $ENV{LENA}
    ? @{ &LENA_DEFAULT_MAPS }
    : @{ &DEFAULT_MAPS };
  foreach (@maps){
    $self->{db}->addMap( @{$_}{ qw/mapName playersNum turnsNum/}, exists($_->{regions}) ? encode_json($_->{regions}) : "[]");
  }
}

sub cmd_uploadMap {
  my ($self, $js, $result) = @_;
  $result->{mapId} = $self->{db}->addMap(
    @$js{qw/mapName playersNum turnsNum/},
    encode_json($js->{regions}));
}

sub cmd_createGame {
  my ($self, $js, $result) = @_;
  $js->{ai} = $js->{ai} // 0;
  my @params = (@$js{qw/sid gameName mapId gameDescription ai/}, $self->getGameInitialGeneratedNum($js));
  $result->{gameId} = $self->{db}->gameWithNameExists($js->{gameName}, 1)
    ? $self->{db}->updateGame( @params )
    : $self->{db}->createGame( @params );
}


sub cmd_getGameList {
  my ($self, $js, $result) = @_;
  my $ref = $self->{db}->getGames();
  $result->{games} = [];
  foreach ( @$ref ) {
    my $players = [];
    my ($activePlayerId, $turn) = (undef, 0);
    if ( $_->{GSTATE} == GST_WAIT ) {
      my $pl = $self->{db}->getPlayers($_->{ID});
      $players = [
        map { {
          'userId'   => $_->{ID},
          'username' => $_->{USERNAME},
          'isReady'  => $self->bool($_->{ISREADY}),
          'inGame'   => $self->bool(1)
        } } @$pl
      ];
    }
    else {
      my $game = $self->getGame($js, $_->{ID}, 1);
      $activePlayerId = $game->{gameState}->{activePlayerId};
      $turn = $game->{gameState}->{currentTurn};
      $players = [
        map { {
          'userId'   => $_->{playerId},
          'username' => $_->{username},
          'isReady'  => $self->bool(1),
          'inGame'   => $self->bool($_->{inGame})
        } } @{ $game->{gameState}->{players} }
      ];
    }
    push @{$result->{games}}, { 'gameId' => $_->{ID}, 'gameName' => $_->{NAME}, 'gameDescription' => $_->{DESCRIPTION},
                                'mapId' => $_->{MAPID}, 'maxPlayersNum' => $_->{PLAYERSNUM}, 'turnsNum' => $_->{TURNSNUM},
                                'state' => $_->{GSTATE}, 'activePlayerId' => $activePlayerId, 'turn' => $turn,
                                'players' => $players, 'picture' => $self->getMapUrl($_->{MAPID}),
                                'aiRequiredNum' => $_->{AINUM} };
  }
}

sub cmd_getMapList {
  my ($self, $js, $result) = @_;
  $result->{maps} = [
    map { {
      'mapId'       => $_->{ID},
      'mapName'     => $_->{NAME},
      'playersNum'  => $_->{PLAYERSNUM},
      'turnsNum'    => $_->{TURNSNUM},
      'picture'     => $self->getMapUrl($_->{ID}),
      'regions'     => [
        map { {
          constRegionState => $_->{landDescription},
          coordinates      => $_->{coordinates},
          raceCoords       => $_->{raceCoords},
          powerCoords      => $_->{powerCoords}
        } } @{ decode_json($_->{REGIONS}) }
      ]
    } } @{$self->{db}->getMaps()}
  ];
}

sub cmd_joinGame {
  my ($self, $js, $result) = @_;
  $self->{db}->joinGame( @$js{qw/gameId sid/} );
}

sub cmd_leaveGame {
  my ($self, $js, $result) = @_;
  my $sid = $js->{sid};
  my $gameId = $self->{db}->getGameId($sid);
  my $gst = $self->{db}->getGameStateOnly($gameId);
  if ( $gst == GST_BEGIN || $gst == GST_IN_GAME ) {
    my $game = $self->getGame($js, $gameId);
    $game->forceDecline($self->{db}->getPlayerId($sid));
    $game->save();
  }
  $self->{db}->leaveGame($sid);
}

sub cmd_setReadinessStatus {
  my ($self, $js, $result) = @_;
  if ($self->{db}->setIsReady( @$js{qw/isReady sid/} ) ) {
    my $game = $self->getGame($js);
    if ( ($self->{loading} || $ENV{DEBUG}) && exists $js->{visibleRaces} && exists $js->{visibleSpecialPowers} ) {
      $game->setTokenBadge('raceName', $js->{visibleRaces});
      $game->setTokenBadge('specialPowerName', $js->{visibleSpecialPowers});
    }
    $game->save();
  }
}

sub cmd_aiJoin {
  my ($self, $js, $result) = @_;
  my ($id, $sid) = $self->{db}->aiJoin($js->{gameId});
  if ( !defined $id ) {
    $result->{result} = R_TOO_MANY_AI;
    return;
  }
  $result->{id} = $id;
  $result->{sid} = $sid;
  if ( $self->{db}->tryBeginGame($js->{gameId}) ) {
    $self->getGame($js)->save();
  }
}

sub cmd_saveGame {
  my ($self, $js, $result) = @_;
  $result->{actions} = [];
  foreach ( @{ $self->{db}->getHistory($js->{gameId}) } ) {
    my $cmd = decode_json($_);
    if ( $cmd->{action} eq 'createGame' ) {
      $cmd->{randseed} = $self->{db}->getGameGenNum($js->{gameId});
    }
    if ( exists $cmd->{dice} ) {
      delete $cmd->{dice};
    }
    push @{ $result->{actions} }, $cmd;
  }
}

sub cmd_loadGame {
  my ($self, $js, $result) = @_;
  my @cmds = (@{ $js->{actions} });
  my $gameId = undef;
  $self->{loading} = 1;
  foreach ( @cmds ) {
    if ( exists $_->{userId} ) {
      # если есть userId, то подменяем его на sid
      $_->{sid} = $self->{db}->getSid($_->{userId});
      delete $_->{userId};
    }
    my $res = $self->checkAndDo($_);
    if ( $res->{result} eq R_ALL_OK && $_->{action} eq 'createGame' ) {
      $gameId = $result->{gameId};
    }
    if ( $res->{result} ne R_ALL_OK && ($_->{action} ne 'conquer' || exists $res->{dice}) ) {
      $result->{result} = $res->{result};
      if ( defined $gameId ) {
        # отключаем всех игроков от игры (заодно удалится история и игра
        # пометиться на удаление
        foreach ( @{ $self->{db}->getConnections($gameId) } ) {
          $self->{db}->leaveGame($_);
        }
      }
      last;
    }
  }
  $self->{loading} = 0;
}

sub cmd_selectRace {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->selectRace($js->{position}, $result);
  $game->save();
  $self->{db}->updateGameStateOnly($game->{gameState}->{gameInfo}->{gameId}, GST_IN_GAME);
}

sub cmd_conquer {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->conquer($js->{regionId}, $result);
  $game->save();
}

sub cmd_decline {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->decline();
  $game->save();
}

sub cmd_finishTurn {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->finishTurn($result);
  $game->save();
  $self->{db}->finishGame($game->id) if $game->stage eq GS_IS_OVER;
}

sub cmd_redeploy {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->redeploy(@$js{qw( regions encampments fortified heroes )});
  $game->save();
}

sub cmd_defend {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->defend($js->{regions});
  $game->save();
}

sub cmd_enchant {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->enchant($js->{regionId});
  $game->save();
}

sub cmd_selectFriend {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->selectFriend($js->{friendId});
  $game->save();
}

sub cmd_dragonAttack {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $game->dragonAttack($js->{regionId});
  $game->save();
}

sub cmd_throwDice {
  my ($self, $js, $result) = @_;
  my $game = $self->getGame($js);
  $result->{dice} = $game->throwDice($js->{dice});
  $game->save();
}

sub cmd_getGameState {
  my ($self, $js, $result) = @_;
  $result->{gameState} = $self->getGame($js)->getGameStateForPlayer();
}

1;

__END__
