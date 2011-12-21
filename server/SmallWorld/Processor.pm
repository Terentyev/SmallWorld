package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON qw(encode_json decode_json);
use File::Basename qw(basename);

use SmallWorld::Consts;
use SmallWorld::Config;
use SmallWorld::DB;
use SmallWorld::Checker;
use SmallWorld::Game;
use SmallWorld::Utils;

sub new {
  my $class = shift;
  my $self = { json => undef, db => undef, _game => undef };

  $self->{db} = SmallWorld::DB->new();
  $self->{db}->connect(DB_NAME, DB_LOGIN, DB_PASSWORD, DB_MAX_BLOB_SIZE);

  bless $self, $class;
  return $self;
}

sub process {
  my ($self, $r) = @_;
  if ( !defined $r ) {
    $r = '{}';
  }
  $self->{json} = eval { return decode_json($r) or {}; };

  my $result = { result => R_ALL_OK };
  $self->checkJsonCmd($result);

  $self->saveCmd($result) if ($self->{json}->{action} // '') eq 'leaveGame';
  if ( $result->{result} eq R_ALL_OK ) {
    no strict 'refs';
    &{"cmd_$self->{json}->{action}"}($self, $result);
  }
  $self->saveCmd($result) if ($self->{json}->{action} // 'leaveGame') ne 'leaveGame';
  if ( $ENV{LENA} ) {
    # у Лены sid проверяется только как число, а наш сервер почему-то возвращает
    # строку... Ничего лучше пока не придумано.
    if ( $self->{json}->{action} eq 'login' && $result->{result} eq R_ALL_OK ) {
      $result->{sid} *= 1;
    }
  }
  print encode_json($result)."\n" or die "Can not encode JSON-object\n";
  $self->{_game} = undef;
}

sub debug {
  return if !$ENV{DEBUG};
  use Data::Dumper;
  open FL, '>>' . LOG_FILE;
  print FL Dumper(@_);
  close FL;
}

sub getGame {
  my $self = shift;
  my $id = defined $_[0]
    ? $_[0]
    : (defined $self->{json}->{gameId}
        ? $self->{json}->{gameId}
        : $self->{db}->getGameId($self->{json}->{sid}));

  my $version = $self->{db}->getGameVersion($id);

#  my ($version, $id) = @{ $self->{db}->getGameVersionAndId($self->{json}->{gameId}) };
  if ( !defined $self->{_game} ||
      (grep { $_->{isReady} == 0 } @{ $self->{_game}->{gameState}->{players} }) ||
      $self->{_game}->{gameState}->{gameInfo}->{gameId} != $id ||
      $self->{_game}->{_version} != $version ) {
    $self->{_game} = SmallWorld::Game->new($self->{db}, $id, $self->{json}->{action});
  }
  return $self->{_game};
}

sub needSaveCmd {
  my ($self, $result) = @_;
  return 1 if $self->{json}->{action} eq 'conquer' && defined $result->{dice};
  return 0 if $result->{result} ne R_ALL_OK;
  foreach ( qw( createGame joinGame leaveGame setReadinessStatus selectRace conquer dragonAttack enchant throwDice decline defend redeploy selectFriend finishTurn ) ) {
    return 1 if $_ eq $self->{json}->{action};
  }
  return 0;
}

sub saveCmd {
  my ($self, $result) = @_;
  return if !$self->needSaveCmd($result);

  my $cmd = { %{ $self->{json} } };
  my $gameId = $cmd->{gameId};
  if ( exists $cmd->{sid} ) {
    $cmd->{userId} = $self->{db}->getPlayerId($cmd->{sid});
    $gameId = $self->{db}->getGameId($cmd->{sid});
    delete $cmd->{sid};
  }
#  if ( $self->{json}->{action} eq 'conquer' && defined $result->{dice} ) {
#    $cmd->{dice} = $result->{dice};
#  }
  $self->{db}->saveCommand($gameId, encode_json($cmd));
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
  return undef;
}

sub getGameInitialGeneratedNum {
  return int(rand(RAND_EXPR));
}

# Команды, которые приходят от клиента
sub cmd_resetServer {
  return if !$ENV{DEBUG};
  my ($self, $result) = @_;
  $self->{db}->clear();
}

sub cmd_register {
  my ($self, $result) = @_;
  $self->{db}->addPlayer( @{$self->{json}}{qw/username password/} );
}

sub cmd_login {
  my ($self, $result) = @_;
  $result->{sid} = $self->{db}->makeSid( @{$self->{json}}{qw/username password/} );
  $result->{userId} = $self->{db}->getPlayerId($result->{sid});
}

sub cmd_logout {
  my ($self, $result) = @_;
  $self->{db}->logout($self->{json}->{sid});
}

sub cmd_sendMessage {
  my ($self, $result) = @_;
  $self->{db}->addMessage( @{$self->{json}}{qw/sid text/} );
}

sub cmd_getMessages {
  my ($self, $result) = @_;
  my $ref = $self->{db}->getMessages($self->{json}->{since});
  my @a = ();
  foreach (@{$ref}) {
    push @a, { 'id' => $_->{ID}, 'text' => $_->{TEXT}, 'username' => $_->{USERNAME}, 'time' => TEST_MODE ? $_->{ID} : $_->{T} };
  }
  @{$result->{messages}} = reverse @a;
}

sub cmd_createDefaultMaps {
  return if !$ENV{DEBUG};
  my ($self, $result) = @_;
  my @maps = $ENV{LENA}
    ? @{ &LENA_DEFAULT_MAPS }
    : @{ &DEFAULT_MAPS };
  foreach (@maps){
    $self->{db}->addMap( @{$_}{ qw/mapName playersNum turnsNum/}, exists($_->{regions}) ? encode_json($_->{regions}) : "[]");
  }
}

sub cmd_uploadMap {
  my ($self, $result) = @_;
  $result->{mapId} = $self->{db}->addMap(
    @{$self->{json}}{qw/mapName playersNum turnsNum/},
    encode_json($self->{json}->{regions}));
}

sub cmd_createGame {
  my ($self, $result) = @_;
  my $js = $self->{json};
  my @params = (@{$js}{qw/sid gameName mapId gameDescription/}, $self->getGameInitialGeneratedNum());
  $result->{gameId} = $self->{db}->gameWithNameExists($js->{gameName}, 1)
    ? $self->{db}->updateGame( @params )
    : $self->{db}->createGame( @params );
}


sub cmd_getGameList {
  my ($self, $result) = @_;
  my $ref = $self->{db}->getGames();
  $result->{games} = [];
  foreach ( @{$ref} ) {
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
        } } @{$pl}
      ];
    }
    else {
      my $game = $self->getGame($_->{ID});
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
                                'players' => $players, 'url' => $self->getMapUrl($_->{MAPID})};
  }
}

sub cmd_getMapList {
  my ($self, $result) = @_;
  $result->{maps} = [
    map { {
      'mapId'       => $_->{ID},
      'mapName'     => $_->{NAME},
      'playersNum'  => $_->{PLAYERSNUM},
      'turnsNum'    => $_->{TURNSNUM},
      'url'         => $self->getMapUrl($_->{ID}),
      'regions'     => [
        map { {
          coordinates => $_->{coordinates},
          raceCoords  => $_->{raceCoords},
          powerCoords => $_->{powerCoords}
        } } @{ decode_json($_->{REGIONS}) }
      ]
    } } @{$self->{db}->getMaps()}
  ];
}

sub cmd_joinGame {
  my ($self, $result) = @_;
  $self->{db}->joinGame( @{$self->{json}}{qw/gameId sid/} );
}

sub cmd_leaveGame {
  my ($self, $result) = @_;
  my $sid = $self->{json}->{sid};
  my $gameId = $self->{db}->getGameId($sid);
  my $gst = $self->{db}->getGameStateOnly($gameId);
  if ( $gst == GST_BEGIN || $gst == GST_IN_GAME ) {
    my $game = $self->getGame($gameId);
    $game->forceDecline($self->getPlayerId($sid));
    $game->save();
  }
  $self->{db}->leaveGame($sid);
}

sub cmd_setReadinessStatus {
  my ($self, $result) = @_;
  if ($self->{db}->setIsReady( @{$self->{json}}{qw/isReady sid/} ) ) {
    my $game = $self->getGame();
    if ( $ENV{DEBUG} && exists $self->{json}->{visibleRaces} && exists $self->{json}->{visibleSpecialPowers} ) {
      $game->setTokenBadge('raceName', $self->{json}->{visibleRaces});
      $game->setTokenBadge('specialPowerName', $self->{json}->{visibleSpecialPowers});
    }
    $game->save();
  }
}

sub cmd_saveGame {
  my ($self, $result) = @_;
  $result->{actions} = [];
  foreach ( @{ $self->{db}->getHistory($self->{json}->{gameId}) } ) {
    my $cmd = decode_json($_);
    if ( $cmd->{action} eq 'createGame' ) {
      $cmd->{randseed} = $self->{db}->getGameGenNum($self->{json}->{gameId});
    }
    push @{ $result->{actions} }, $cmd;
  }
}

sub cmd_selectRace {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->selectRace($self->{json}->{position}, $result);
  $game->save();
}

sub cmd_conquer {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->conquer($self->{json}->{regionId}, $result);
  $game->save();
}

sub cmd_decline {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->decline();
  $game->save();
}

sub cmd_finishTurn {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->finishTurn($result);
  $game->save();
}

sub cmd_redeploy {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->redeploy(@{ $self->{json} }{qw( regions encampments fortified heroes )});
  $game->save();
}

sub cmd_defend {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->defend($self->{json}->{regions});
  $game->save();
}

sub cmd_enchant {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->enchant($self->{json}->{regionId});
  $game->save();
}

sub cmd_selectFriend {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->selectFriend($self->{json}->{friendId});
  $game->save();
}

sub cmd_dragonAttack {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->dragonAttack($self->{json}->{regionId});
  $game->save();
}

sub cmd_throwDice {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $result->{dice} = $game->throwDice($self->{json}->{dice});
  $game->save();
}

sub cmd_getGameState {
  my ($self, $result) = @_;
  $result->{gameState} = $self->getGame()->getGameStateForPlayer();
}

1;

__END__
