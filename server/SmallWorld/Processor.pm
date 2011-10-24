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
  my $self = { json => undef, db => undef };
  my ($r) = @_;
  if ( !$r ) {
    $r = '{}';
  }
  $self->{json} = eval { return decode_json($r) or {}; };
  $self->{db} = SmallWorld::DB->new;

  bless $self, $class;
  return $self;
}

sub process {
  my ($self) = @_;
  $self->{db}->connect(DB_NAME, DB_LOGIN, DB_PASSWORD, DB_MAX_BLOB_SIZE);

  my $result = { result => $self->checkJsonCmd() };

  if ( $result->{result} eq R_ALL_OK ) {
    no strict 'refs';
    &{"cmd_$self->{json}->{action}"}($self, $result);
  }
  $self->{db}->disconnect;
  print encode_json($result)."\n" or die "Can not encode JSON-object\n";
}

sub debug {
  return if !$ENV{DEBUG};
  use Data::Dumper; print Dumper(@_);
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
  #TO DO
  $self->{json}->{visibleRaces};
  $self->{json}->{visiblePowers};
}

sub cmd_selectRace {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{position};
}

sub cmd_conquer {
  my ($self, $result) = @_;
  $self->{json}->{regionId};
  my $game = SmallWorld::Game->new($self->{db}, $self->{json}->{sid});
}

sub cmd_decline {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_finishTurn {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_redeploy {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{raceId};
  $self->{json}->{regions};
}

sub cmd_defend {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{regions};
}

sub cmd_enchant {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{regionId};
}

sub cmd_getVisibleTokenBadges {
  my ($self, $result) = @_;
  $self->{json}->{gameId};
}

sub cmd_throwDice {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{dice};
}

sub cmd_getGameState {
  my ($self, $result) = @_;
  $result->{gameState} = SmallWorld::Game->new(
      $self->{db}, $self->{json}->{sid})->getGameStateForPlayer($self->{json}->{sid});
}

1;

__END__
