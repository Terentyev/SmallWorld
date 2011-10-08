package SmallWorld::DB;

use strict;
use warnings;
use utf8;

use SmallWorld::Config;
use DBD::InterBase;
use DBI;

sub new {
  my $class = shift;
  my $self = {};
  $self->{dbh} = undef;
  $self->{dbTables} = ["PLAYERS", "MAPS", "GAMES", "MESSAGES"];
  $self->{dbGenerators} = ["GEN_MAP_ID", "GEN_GAME_ID", "GEN_MESSAGE_ID", "GEN_SID", "GEN_PLAYER_ID"];
  bless $self, $class;
  return $self
}

sub dbError {
  my $self = shift;
  my $error =  defined $_[0] ? $_[0] : $self->{dbh}->errstr;
  die "DB error: $error";
}

sub connect {
  my $self = shift;
  my ($dbName, $dbLogin, $dbPassword, $dbMaxBlobSize) = @_;
  $self->{dbh} = DBI->connect("DBI:InterBase:hostname=localhost;db=$dbName", $dbLogin, $dbPassword)
    or $self->dbError;
  $self->{dbh}->{LongReadLen} = $dbMaxBlobSize if $dbMaxBlobSize;
  $self->{dbh}->{AutoCommit} = 1;
}

sub disconnect {
  $_[0]->{dbh}->disconnect;
}

sub _do {
  my $self = shift;
  my ($s, @list) = @_;
  $self->{dbh}->do($s, undef, @list) or $self->dbError;
}

sub query {
  my $self = shift;
  my $sql = shift;
  return $self->{dbh}->selectrow_array($sql, undef, @_)
}

sub dbExists {
  my $self = shift;
  my ($table, $field, $param) = @_;
  return defined $self->query("SELECT 1 FROM $table WHERE $field = ?", $param);
}

sub clear {
  my $self = shift;
  foreach (@{$self->{dbTables}}){
    $self->_do("DELETE FROM $_");
  }
  foreach (@{$self->{dbGenerators}}){
    $self->_do("SET GENERATOR $_ TO 0");
  }
}

sub addPlayer {
  my $self = shift;
  $self->_do("INSERT INTO PLAYERS(username, pass) VALUES(?,?)", @_);
}

sub getSid {
  my $self = shift;
  return $self->query("EXECUTE PROCEDURE MAKESID(?,?)", @_);
}

1;

