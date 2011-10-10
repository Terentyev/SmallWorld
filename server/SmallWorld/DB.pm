package SmallWorld::DB;

use strict;
use warnings;
use utf8;

use SmallWorld::Config;
use SmallWorld::Consts;
use DBD::InterBase;
use DBI;

sub new {
  my $class = shift;
  my $self = {};
  $self->{dbh} = undef;
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

sub _getId {
  my $self = shift;
  my $name = uc shift;
  return $self->{dbh}->selectrow_array("SELECT gen_id(GEN_$name\_ID, 0) FROM RDB\$DATABASE");
}

sub _getPlayerId {
  my $self = shift;
  return $self->query("SELECT id FROM PLAYERS WHERE sid = ?", @_);
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
  foreach (@{&DB_TABLES_NAMES}){
    $self->_do("DELETE FROM $_");
  }
  foreach (@{&DB_GENERATORS_NAMES}){
    $self->_do("SET GENERATOR $_ TO 0");
  }
}

sub addMap {
  my $self = shift;
  $self->_do("INSERT INTO MAPS (name, playersNum, turnsNum, regions) VALUES (?, ?, ?, ?)", @_);
  return $self->_getId("MAP");
}

sub addPlayer {
  my $self = shift;
  $self->_do("INSERT INTO PLAYERS (username, pass) VALUES(?,?)", @_);
}

sub createGame {
  my ($self, $h) = @_;
  $h->{gameDescr} = "" if !exists $h->{gameDescr};
  $self->_do("INSERT INTO GAMES (name, mapId, description) VALUES (?, ?, ?)", $h->{gameName}, $h->{mapId}, $h->{gameDescr});
  my $game_id = $self->_getId("GAME");
  $self->_do("UPDATE PLAYERS SET gameId = ? WHERE sid = ?", $game_id, $h->{sid});
  return $game_id;
}

sub makeSid {
  my $self = shift;
  return $self->query("EXECUTE PROCEDURE MAKESID(?,?)", @_);
}

sub logout {
  my $self = shift;
  $self->_do("EXECUTE PROCEDURE LOGOUT(?)", @_);
}
1;

