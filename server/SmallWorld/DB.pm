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
  my $error = defined $_[0] ? $_[0] : $self->{dbh}->errstr;
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
  $self->{dbh}->do($s, undef, @list) or $self->dbError();
}

sub _getId {
  my $self = shift;
  my $name = uc shift;
  return $self->{dbh}->selectrow_array("SELECT gen_id(GEN_$name\_ID, 0) FROM RDB\$DATABASE");
}

sub getPlayerId {
  my $self = shift;
  return $self->query("SELECT id FROM PLAYERS WHERE sid = ?", @_);
}

sub getGameId {
  my $self = shift;
  return $self->query("SELECT gameId FROM PLAYERS WHERE sid = ?", @_);
}

sub query {
  my $self = shift;
  my $sql = shift;
  return $self->{dbh}->selectrow_array($sql, undef, @_) or $self->dbError();
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
  my $self = shift;
  my ($sid, $gameName, $mapId, $gameDescr) = @_;
  $gameDescr = "" if !defined $gameDescr;
  $self->_do("INSERT INTO GAMES (name, mapId, description) VALUES (?, ?, ?)", $gameName, $mapId, $gameDescr);
  my $game_id = $self->_getId("GAME");
  $self->_do("UPDATE PLAYERS SET gameId = ? WHERE sid = ?", $game_id, $sid);
  return $game_id;
}

sub joinGame {
  my $self = shift;
  $self->_do("UPDATE PLAYERS SET gameId = ? WHERE sid = ?", @_);
}

sub makeSid {
  my $self = shift;
  return $self->query("EXECUTE PROCEDURE MAKESID(?,?)", @_);
}

sub logout {
  my $self = shift;
  $self->leaveGame($_[0]);
  $self->_do("EXECUTE PROCEDURE LOGOUT(?)", $_[0]);
}

sub playersCount {
  my $self = shift;
  return $self->query("SELECT COUNT(*) FROM PLAYERS WHERE gameId = ?", $_[0]);
}

sub readyCount {
  my $self = shift;
  return $self->query("SELECT COUNT(*) FROM PLAYERS WHERE isReady = 1 AND gameId = ?", $_[0]);
}

sub getGameIsStarted {
  my $self = shift;
  return $self->query("SELECT isStarted FROM GAMES WHERE id = ?", $_[0]);
}

sub leaveGame {
  my $self = shift;
  my $gameId = $self->getGameId($_[0]);
  if (defined $gameId) {
    $self->_do("UPDATE PLAYERS SET isReady = 0, gameId = NULL WHERE sid = ?", $_[0]);
    $self->_do("DELETE FROM GAMES WHERE id = ?", $gameId) if !$self->playersCount($gameId);
  }
}

sub setIsReady {
  my $self = shift;
  my ($isReady, $sid) = @_;
  my $gameId = $self->getGameId($sid);
  $self->_do("UPDATE PLAYERS SET isReady = ? WHERE sid = ?", $isReady, $sid);
  $self->_do("UPDATE GAMES SET isStarted = 1 WHERE id = ?", $gameId)
    if $self->readyCount($gameId) == $self->getMaxPlayers($gameId);
}

sub getMaxPlayers {
  my $self = shift;
  return $self->query("SELECT playersNum FROM MAPS m INNER JOIN GAMES g ON m.id = g.mapId WHERE g.id = ?", $_[0]);
}

sub addMessage {
  my $self = shift;
  my ($sid, $text) = @_;
  $self->_do("INSERT INTO MESSAGES (text, userId) VALUES (?, ?)", $text, $self->getPlayerId($sid));
}

sub getMessages {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref("SELECT id, text, userId FROM MESSAGES WHERE id > ? ",
                                          { Columns => [1,2,3] }, $_[0]) or dbError;
}

sub getMaps {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref("SELECT id, name, playersNum, turnsNum FROM MAPS",
                                          { Columns => [1, 2, 3, 4] }) or dbError;
}

sub getGameState {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref('SELECT g.id, g.name, g.description, g.mapId, g.state, COUNT(p.id) AS currentPlayersNum FROM GAMES g INNER JOIN PLAYERS p ON p.gameId = g.id WHERE p.sid = ? GROUP BY 1, 2, 3, 4, 5',
      { Columns => [1, 2, 3, 4, 5, 6] }, $_[0]);
}

sub saveGameState {
  my $self = shift;
  $self->{dbh}->_do('UPDATE GAMES SET state = ? WHERE id = ?', @_);
}

sub getMap {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref('SELECT id, name, playersNum, turnsNum, regions FROM MAPS WHERE id = ?',
      { Columns => [1, 2, 3, 4, 5] }, $_[0]);
}

sub getPlayers {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref('SELECT id, username, isReady FROM PLAYERS WHERE gameId = ?',
      { Columns => [1, 2, 3] }, $_[0]);
}

1;

