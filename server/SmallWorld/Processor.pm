package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON qw(encode_json decode_json);

use SmallWorld::Consts;
use SmallWorld::Config;
use SmallWorld::DB;
use SmallWorld::Checker;
use SmallWorld::Game;

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

  if ( $result->{result} eq R_ALL_OK ) {
    no strict 'refs';
    &{"cmd_$self->{json}->{action}"}($self, $result);
  }
  print encode_json($result)."\n" or die "Can not encode JSON-object\n";
}

sub debug {
  return if !$ENV{DEBUG};
  use Data::Dumper; print Dumper(@_);
}

sub getGame {
  my $self = shift;
  if ( !defined $self->{_game} ||
      $self->{_game}->{_version} != $self->{_game}->getGameVersion($self->{json}->{sid}) ) {
    $self->{_game} = SmallWorld::Game->new($self->{db}, $self->{json}->{sid});
  }
  return $self->{_game};
}

# Команды, которые приходят от клиента
sub cmd_resetServer {
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
    push @a, { 'id' => $_->{ID}, 'text' => $_->{TEXT}, 'userName' => $_->{USERNAME}, 'time' => TEST_MODE ? $_->{ID} : $_->{T} };
  }
  @{$result->{messages}} = reverse @a;
}

sub cmd_createDefaultMaps {
  my ($self, $result) = @_;
  foreach (@{&DEFAULT_MAPS}){
    $self->{db}->addMap( @{$_}{ qw/mapName playersNum turnsNum/}, exists($_->{regions}) ? encode_json($_->{regions}) : "[]");
  }
}

sub cmd_uploadMap {
  my ($self, $result) = @_;
  $result->{mapId} = $self->{db}->addMap( @{$self->{json}}{qw/mapName playersNum turnsNum/}, encode_json($self->{json}->{regions}));
}

sub cmd_createGame {
  my ($self, $result) = @_;
  $result->{gameId} = $self->{db}->createGame( @{$self->{json}}{qw/sid gameName mapId gameDescr/} );
}


sub cmd_getGameList {
  my ($self, $result) = @_;
  my $ref = $self->{db}->getGames();
  $result->{games} = [];
  foreach ( @{$ref} ) {
    my $pl = $self->{db}->getPlayers($_->{ID});
    my $players = [
      map { {
        'userId' => $_->{ID},
        'userName' => $_->{USERNAME},
        'isReady' => $_->{ISREADY}
      } } @{$pl}
    ];
    my ($activePlayerId, $turn) = (undef, 0);
    #TO DO сделать для начатых игр
    push @{$result->{games}}, { 'gameId' => $_->{ID}, 'gameName' => $_->{NAME}, 'gameDescription' => $_->{DESCRIPTION},
                                'mapId' => $_->{MAPID}, 'maxPlayersNum' => $_->{PLAYERSNUM}, 'turnsNum' => $_->{TURNSNUM},
                                'state' => $_->{ISSTARTED} + 1, 'activePlayerId' => $activePlayerId, 'turn' => $turn,
                                'players' => $players };
  }
}

sub cmd_getMapList {
  my ($self, $result) = @_;
  $result->{maps} = [
    map { {
      'mapId' => $_->{ID},
      'mapName' => $_->{NAME},
      'playersNum' => $_->{PLAYERSNUM},
      'turnsNum' => $_->{TURNSNUM}
    } } @{$self->{db}->getMaps()}
  ];
}

sub cmd_joinGame {
  my ($self, $result) = @_;
  $self->{db}->joinGame( @{$self->{json}}{qw/gameId sid/} );
}

sub cmd_leaveGame {
  my ($self, $result) = @_;
  $self->{db}->leaveGame($self->{json}->{sid});
}

sub cmd_setReadinessStatus {
  my ($self, $result) = @_;
  $self->{db}->setIsReady( @{$self->{json}}{qw/isReady sid/} );
  #TODO
  $self->{json}->{visibleRaces};
  $self->{json}->{visiblePowers};
}

sub cmd_selectRace {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->selectRace($self->{json}->{position});
  $game->save();
}

sub cmd_conquer {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->conquer($self->{json}->{regionId});
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
  $game->finishTurn();
  $game->save();
}

sub cmd_redeploy {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $game->redeploy($self->{json}->{qw( regions encampments fortified heroes )});
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

sub cmd_throwDice {
  my ($self, $result) = @_;
  my $game = $self->getGame();
  $result->{dice} = $game->throwDice();
  $game->save();
}

sub cmd_getGameState {
  my ($self, $result) = @_;
  $result->{gameState} = $self->getGame()->getGameStateForPlayer($self->{json}->{sid});
}

1;

__END__
