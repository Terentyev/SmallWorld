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
  return $self->query('SELECT id FROM PLAYERS WHERE sid = ?', @_);
}

sub getGameId {
  my $self = shift;
  return $self->query('SELECT c.gameId FROM CONNECTIONS c INNER JOIN PLAYERS p ON p.id = c.playerId WHERE p.sid = ?', @_);
}

sub getSid {
  my ($self, $playerId) = @_;
  return $self->query('SELECT sid FROM PLAYERS WHERE id = ?', $playerId);
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
  $self->_do('
      INSERT INTO MAPS (name, playersNum, turnsNum, regions)
      VALUES (?, ?, ?, ?)',
      @_);
  return $self->_getId('MAP');
}

sub addPlayer {
  my $self = shift;
  $self->_do('INSERT INTO PLAYERS (username, pass) VALUES(?,?)', @_);
}

sub createGame {
  my $self = shift;
  my ($sid, $gameName, $mapId, $gameDescr) = @_;
  $self->_do('INSERT INTO GAMES (name, mapId, description) VALUES (?, ?, ?)',
             $gameName, $mapId, !defined $gameDescr ? '' : $gameDescr);
  my $gameId = $self->_getId('GAME');
  $self->joinGame($gameId, $sid);
  return $gameId;
}

sub updateGame {
  my ($self, $sid, $gameName, $mapId, $gameDescr) = @_;
  $self->_do('
      UPDATE GAMES
      SET mapId = ?, description = ?, gstate = ?, version = 0,
          activePlayerId = NULL, currentTurn = NULL, state = NULL
      WHERE name = ?',
      $mapId, !defined $gameDescr ? '' : $gameDescr, GST_WAIT, $gameName);
  my $gameId = $self->query('SELECT id FROM GAMES WHERE name = ?', $gameName);
  $self->_do('DELETE FROM CONNECTIONS WHERE gameId = ?', $gameId);
  $self->joinGame($gameId, $sid);
  return $gameId;
}

sub joinGame {
  my $self = shift;
  my ($gameId, $sid) = @_;
  $self->_do('INSERT INTO CONNECTIONS (gameId, playerId) VALUES (?, ?)', $gameId, $self->getPlayerId($sid));
}

sub makeSid {
  my $self = shift;
  return $self->query('EXECUTE PROCEDURE MAKESID(?,?)', @_);
}

sub logout {
  my $self = shift;
  $self->leaveGame($_[0]);
  $self->_do('EXECUTE PROCEDURE LOGOUT(?)', $_[0]);
}

sub playersCount {
  my $self = shift;
  return $self->query('SELECT COUNT(*) FROM CONNECTIONS WHERE gameId = ?', $_[0]);
}

sub readyCount {
  my $self = shift;
  return $self->query('SELECT COUNT(c.id) FROM CONNECTIONS c
                       WHERE c.isReady = 1 AND c.gameId = ?', $_[0]);
}

sub leaveGame {
  my ($self, $sid) = @_;
  my $gameId = $self->getGameId($sid);
  if ( defined $gameId ) {
    $self->_do('DELETE FROM CONNECTIONS WHERE playerId = ?', $self->getPlayerId($sid));
    my $count = $self->playersCount($gameId);
    if ( !$count ) {
      $self->_do('DELETE FROM HISTORY WHERE gameId = ?', $gameId);
      $self->_do('UPDATE GAMES SET gstate = ? WHERE id = ?', GST_EMPTY, $gameId);
    }
    elsif ( $count == 1 ) {
      $self->_do('UPDATE GAMES SET gstate = ? WHERE id = ? AND gstate <> ?', GST_FINISH, $gameId, GST_WAIT);
    }
  }
}

sub getConnectionsSid {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref('
      SELECT p.sid
      FROM CONNECTIONS c
      INNER JOIN PLAYERS p ON p.id = c.playerId
      WHERE c.gameId = ?',
      { Columns => [1] }, $_[0]);
}

sub getConnections {
  my $self = shift;
  return $self->{dbh}->selectcol_arrayref('SELECT playerId FROM CONNECTIONS WHERE gameId = ?', { Columns => [1] }, $_[0]);
}

sub setIsReady {
  my $self = shift;
  my ($isReady, $sid) = @_;
  my $gameId = $self->getGameId($sid);
  $self->_do('UPDATE CONNECTIONS SET isReady = ? WHERE playerId = ?', $isReady, $self->getPlayerId($sid));
  if ( $self->readyCount($gameId) == $self->getMaxPlayers($gameId) ) {
    $self->_do('UPDATE GAMES SET gstate = ? WHERE id = ?', GST_BEGIN, $gameId);
    return 1;
  }
  return 0;
}

sub getMaxPlayers {
  my $self = shift;
  return $self->query('SELECT playersNum FROM MAPS m INNER JOIN GAMES g ON m.id = g.mapId WHERE g.id = ?', $_[0]);
}

sub addMessage {
  my $self = shift;
  my ($sid, $text) = @_;
  $self->_do('INSERT INTO MESSAGES (text, playerId) VALUES (?, ?)', $text, $self->getPlayerId($sid));
}

sub getMessages {
  my $self = shift;
  return $self->{dbh}->selectall_arrayref('SELECT FIRST 100 m.id, m.text, m.t, p.username FROM MESSAGES m INNER JOIN PLAYERS p ON
                                           m.playerId = p.id WHERE m.id > ? ORDER BY id DESC', { Slice => {} }, $_[0]) or dbError;
}

sub getMaps {
  my $self = shift;
  return $self->{dbh}->selectall_arrayref('
      SELECT id, name, playersNum, turnsNum, regions FROM MAPS',
      { Slice => {} }) or dbError;
}

sub getGameStateOnly {
  my $self = shift;
  return $self->query('SELECT gstate FROM GAMES WHERE id = ?', $_[0]);
}

sub getGameState {
  my $self = shift;
  return $self->{dbh}->selectrow_hashref('
      SELECT g.id, g.name, g.description, g.mapId, g.state, g.gstate, g.version, g.activePlayerId, g.currentTurn
      FROM GAMES g
      INNER JOIN CONNECTIONS c ON c.gameId = g.id
      INNER JOIN PLAYERS p ON p.id = c.playerId
      WHERE g.id = ?',
      undef,  $_[0]) or dbError;
}

sub saveGameState {
  my $self = shift;
  $self->_do('
      UPDATE GAMES
      SET state = ?, version = version + 1, activePlayerId = ?, currentTurn = ?
      WHERE id = ?',
      @_);
}

sub finishGame {
  my ($self, $id) = @_;
  $self->_do('
      UPDATE GAMES
      SET gstate = ?
      WHERE id = ?',
      GST_FINISH, $id);
}

sub gameWithNameExists {
  my ($self, $name, $all) = @_;
  return defined $self->query('SELECT 1 FROM GAMES WHERE name = ?' . ($all ? '' : ' AND gstate <> ' . GST_EMPTY), $name);
}

sub getMap {
  my $self = shift;
  return $self->{dbh}->selectrow_hashref('SELECT id, name, playersNum, turnsNum, regions FROM MAPS WHERE id = ?',
      undef, $_[0]) or dbError;
}

sub getGames {
  my $self = shift;
  return $self->{dbh}->selectall_arrayref('
      SELECT
        g.id, g.name, g.description, g.mapId, g.gstate, m.playersNum, m.turnsNum, g.activePlayerId,
        g.currentTurn
      FROM GAMES g INNER JOIN MAPS m ON g.mapId = m.id
      WHERE g.gstate <> ?',
      { Slice => {} }, GST_EMPTY ) or dbError;
}

sub getPlayers {
  my $self = shift;
  return $self->{dbh}->selectall_arrayref('SELECT p.id, p.userName, c.isReady FROM PLAYERS p INNER JOIN CONNECTIONS c
                                           ON p.id = c.playerId WHERE c.gameId = ? ORDER by c.id', { Slice => {} }, @_ ) or dbError;
}

# возвращает версию состояния игры и ее id по sid'у игрока
sub getGameVersionAndIdBySid {
  my $self = shift;
  return $self->{dbh}->selectrow_arrayref('
      SELECT g.version, g.id FROM GAMES g
      INNER JOIN CONNECTIONS c ON c.gameId = g.id
      INNER JOIN PLAYERS p ON p.id = c.playerId
      WHERE p.sid = ?',
      undef, $_[0]) || [];
}

sub getGameVersion {
  my $self = shift;
#  return $self->{dbh}->selectrow_arrayref('SELECT version FROM GAMES WHERE id = ?', undef, $_[0]) || [];
  return $self->query('SELECT version FROM GAMES WHERE id = ?', $_[0]);
}

sub saveCommand {
  my ($self, $gameId, $data) = @_;
  $self->_do('INSERT INTO HISTORY(gameId, cmd) VALUES(?, ?)', $gameId, $data);
}

sub getHistory {
  my ($self, $gameId) = @_;
  return $self->{dbh}->selectcol_arrayref('SELECT cmd FROM HISTORY WHERE gameId = ?', { Columns => [1] }, $gameId );
}


1;

__END__
