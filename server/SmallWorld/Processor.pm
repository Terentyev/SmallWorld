package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON;

use SmallWorld::Consts;


sub new {
  my $class = shift;
  my $self = { json => undef, db => undef };
  my ($r) = @_;
  if ( !$r ) {
    $r = "{}";
  }

  $self->{json} = eval { return JSON->new->decode($r) or {}; };
#$self->{db} = SmallWorld::DB->new;

  bless $self, $class;

  return $self;
}

sub process {
  my ($self) = @_;
  my $cmd = $self->{json}->{command} || "";
  my $result = { result => R_ALL_OK };
  my $str = "";
  my $funcName = "cmd_$cmd";
  if ( $cmd && exists &{$funcName} ) {
    my $func = \&{$funcName};
    &$func($self, $result);
  }
  else {
    $result->{result} = R_BAD_JSON;
  }
  $str = JSON->new->encode($result) or die "Can not encode JSON-object\n";
  print $str;
}

sub debug {
  return if !$ENV{DEBUG};
  use Data::Dumper; print Dumper(@_);
}


# Команды, которые приходят от клиента
sub cmd_register {
  my ($self, $result) = @_;
  $self->{json}->{username};
  $self->{json}->{password};
}

sub cmd_login {
  my ($self, $result) = @_;
  $self->{json}->{username};
  $self->{json}->{password};
}

sub cmd_logout {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_sendMessage {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{text};
}

sub cmd_getMessages {
  my ($self, $result) = @_;
  $self->{json}->{since};
}

sub cmd_createDefaultMaps {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_uploadMap {
  my ($self, $result) = @_;
  $self->{json}->{mapName};
  $self->{json}->{palyersNum};
  $self->{json}->{regions};
  $self->{json}->{turnsNum};
}

sub cmd_createGame {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{gameName};
  $self->{json}->{mapId};
  $self->{json}->{gameDescr};
}

sub cmd_getGameList {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_joinGame {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{gameId};
}

sub cmd_leaveGame {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_setReadinessStatus {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{isReady};
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
  $self->{json}->{sid};
  $self->{json}->{regionId};
  $self->{json}->{raceId};
}

sub cmd_decline {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_finishTurn {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_doSmtn {
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

sub cmd_resetServer {
  my ($self, $result) = @_;
}

sub cmd_throwDice {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{dice};
}

1;

__END__
