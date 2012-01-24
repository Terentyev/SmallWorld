package SmallWorld::DB;

use strict;
use warnings;
use utf8;

use DBD::InterBase;
use DBI;

use SmallWorld::Config;
use SmallWorld::Consts;

use base('SW::DB');


sub _init {
  my $self = shift;
  $self->SUPER::_init(@_);
  $self->{dbh}->{AutoCommit} = 0;
  $self->{dbh}->func(
      -lock_resolution => { wait => undef },
      'ib_set_tx_param');
}

sub getPlayerId {
  my $self = shift;
  return $self->fetch1('SELECT id FROM PLAYERS WHERE sid = ?', @_);
}

sub getGameId {
  my $self = shift;
  return $self->fetch1('SELECT c.gameId FROM CONNECTIONS c INNER JOIN PLAYERS p ON p.id = c.playerId WHERE p.sid = ?', @_);
}

sub getGameIdByName {
  my ($self, $gameName) = @_;
  return $self->fetch1('SELECT id FROM GAMES WHERE name = ?', $gameName);
}

sub getGameGenNum {
  my ($self, $gameId) = @_;
  return $self->fetch1('SELECT genNum FROM GAMES WHERE id = ?', $gameId);
}

sub getSid {
  my ($self, $playerId) = @_;
  return $self->fetch1('SELECT sid FROM PLAYERS WHERE id = ?', $playerId);
}

sub dbExists {
  my $self = shift;
  my ($table, $field, $param) = @_;
  return defined $self->fetch1("SELECT 1 FROM $table WHERE $field = ?", $param);
}

sub clear {
  my $self = shift;
  foreach (@{&DB_TABLES_NAMES}){
    $self->do("DELETE FROM $_");
  }
  foreach (@{&DB_GENERATORS_NAMES}){
    $self->do("SET GENERATOR $_ TO 0");
  }
}

sub addMap {
  my ($self, $name, $playersNum, $turnsNum, $regions) = @_;
  $self->do('
      INSERT INTO MAPS (name, playersNum, turnsNum, regions)
      VALUES (?, ?, ?, ?)',
      $name, $playersNum, $turnsNum, $regions);
  $self->commit;
  return $self->fetch1('SELECT id FROM MAPS WHERE name = ?', $name);
}

sub addPlayer {
  my $self = shift;
  $self->do('INSERT INTO PLAYERS (username, pass) VALUES(?,?)', @_);
  $self->commit;
}

sub createGame {
  my $self = shift;
  my ($sid, $gameName, $mapId, $gameDescr, $aiNum, $genNum) = @_;
  $self->do('INSERT INTO GAMES (name, mapId, description, aiNum, genNum) VALUES (?, ?, ?, ?, ?)',
             $gameName, $mapId, !defined $gameDescr ? '' : $gameDescr, $aiNum, $genNum);
  $self->commit;
  my $gameId = $self->fetch1('SELECT id FROM GAMES WHERE name = ?', $gameName);
  $self->joinGame($gameId, $sid);
  return $gameId;
}

sub updateGame {
  my ($self, $sid, $gameName, $mapId, $gameDescr, $aiNum, $genNum) = @_;
  $self->do('
      UPDATE GAMES
      SET mapId = ?, description = ?, gstate = ?, aiNum = ?, genNum = ?, version = 0,
          activePlayerId = NULL, currentTurn = NULL, state = NULL
      WHERE name = ?',
      $mapId, !defined $gameDescr ? '' : $gameDescr, GST_WAIT, $aiNum, $genNum, $gameName);
  $self->commit;
  my $gameId = $self->fetch1('SELECT id FROM GAMES WHERE name = ?', $gameName);
  $self->do('DELETE FROM CONNECTIONS WHERE gameId = ?', $gameId);
  $self->commit;
  $self->joinGame($gameId, $sid);
  return $gameId;
}

sub joinGame {
  my $self = shift;
  my ($gameId, $sid) = @_;
  my ($plNum, $aiNum) = ($self->fetch1('
      SELECT m.playersNum, g.aiNum
      FROM GAMES g
      INNER JOIN MAPS m ON (m.id = g.mapId)
      WHERE g.id = ?', $gameId));
  if ( $plNum > $aiNum ) {
    $self->do('INSERT INTO CONNECTIONS (gameId, playerId) VALUES (?, ?)', $gameId, $self->getPlayerId($sid));
    $self->commit;
  }
}

sub aiJoin {
  my ($self, $gameId) = @_;
  my ($id, $sid) = ();
  eval {
    ($id, $sid) = ($self->fetch1('SELECT aiId, aiSid FROM AIJOIN(?)', $gameId)) ;
  };
  return ($id, $sid);
}

sub makeSid {
  my $self = shift;
  return $self->fetch1('EXECUTE PROCEDURE MAKESID(?,?)', @_);
}

sub logout {
  my $self = shift;
  $self->leaveGame($_[0]);
  $self->do('EXECUTE PROCEDURE LOGOUT(?)', $_[0]);
}

sub playersCount {
  my $self = shift;
  return $self->fetch1('SELECT COUNT(*) FROM CONNECTIONS WHERE gameId = ?', $_[0]);
}

sub realPlayersCount {
  my ($self, $gameId) = @_;
  return $self->fetch1('SELECT COUNT(*) FROM CONNECTIONS c INNER JOIN PLAYERS p ON p.id = c.playerId WHERE c.gameId = ? AND p.isAI = 0', $gameId);
}

sub readyCount {
  my $self = shift;
  return $self->fetch1('SELECT COUNT(c.id) FROM CONNECTIONS c
                       WHERE c.isReady = 1 AND c.gameId = ?', $_[0]);
}

sub leaveGame {
  my ($self, $sid) = @_;
  my $gameId = $self->getGameId($sid);
  if ( defined $gameId ) {
    $self->do('DELETE FROM CONNECTIONS WHERE playerId = ?', $self->getPlayerId($sid));
    my $count = $self->playersCount($gameId);
    if ( !$count ) {
      $self->do('DELETE FROM HISTORY WHERE gameId = ?', $gameId);
      $self->do('UPDATE GAMES SET gstate = ? WHERE id = ?', GST_EMPTY, $gameId);
    }
    elsif ( $count == 1 ) {
      $self->do('UPDATE GAMES SET gstate = ? WHERE id = ? AND gstate <> ?', GST_FINISH, $gameId, GST_WAIT);
    }
  }
  $self->commit;
}

sub getConnectionsSid {
  my $self = shift;
  return $self->fetchcol('
      SELECT p.sid
      FROM CONNECTIONS c
      INNER JOIN PLAYERS p ON p.id = c.playerId
      WHERE c.gameId = ?',
      $_[0]);
}

sub getConnections {
  my $self = shift;
  return $self->fetchcol('SELECT playerId FROM CONNECTIONS WHERE gameId = ?', $_[0]);
}

sub setIsReady {
  my $self = shift;
  my ($isReady, $sid) = @_;
  $self->do('UPDATE CONNECTIONS SET isReady = ? WHERE playerId = ?', $isReady, $self->getPlayerId($sid));
  $self->commit;
  return $self->tryBeginGame($self->getGameId($sid));
}

sub tryBeginGame {
  my ($self, $gameId) = @_;
  return 0 if $self->readyCount($gameId) != $self->getMaxPlayers($gameId);

  $self->do('UPDATE GAMES SET gstate = ? WHERE id = ?', GST_BEGIN, $gameId);
  $self->commit;
  return 1;
}

sub getMaxPlayers {
  my $self = shift;
  return $self->fetch1('SELECT playersNum FROM MAPS m INNER JOIN GAMES g ON m.id = g.mapId WHERE g.id = ?', $_[0]);
}

sub getAINum {
  my ($self, $gameId) = @_;
  return $self->fetch1('SELECT aiNum FROM GAMES WHERE id = ?', $gameId);
}

sub getMaxPlayersInMap {
  my ($self, $mapId) = @_;
  return $self->fetch1('SELECT playersNum FROM MAPS WHERE id = ?', $mapId);
}

sub addMessage {
  my $self = shift;
  my ($sid, $text) = @_;
  $self->do('INSERT INTO MESSAGES (text, playerId) VALUES (?, ?)', $text, $self->getPlayerId($sid));
  $self->commit;
}

sub getMessages {
  my $self = shift;
  return $self->fetchall('
      SELECT FIRST 100 m.id, m.text, m.t, p.username
      FROM MESSAGES m
      INNER JOIN PLAYERS p ON m.playerId = p.id
      WHERE m.id > ?
      ORDER BY id DESC',
      $_[0]);
}

sub getMaps {
  return $_[0]->fetchall('SELECT id, name, playersNum, turnsNum, regions FROM MAPS');
}

sub getGameStateOnly {
  my $self = shift;
  return $self->fetch1('SELECT gstate FROM GAMES WHERE id = ?', $_[0]);
}

sub updateGameStateOnly {
  my ($self, $gameId, $gstate) = @_;
  $self->do('UPDATE GAMES SET gstate = ? WHERE id = ?', $gstate, $gameId);
  $self->commit;
  return 1;
}

sub getGameState {
  my $self = shift;
  return $self->fetchrow('
      SELECT
        id, name, description, mapId, state, aiNum, gstate, version, activePlayerId, currentTurn, genNum
      FROM GAMES
      WHERE id = ?',
      $_[0]);
}

sub saveGameState {
  my $self = shift;
  $self->do('
      UPDATE GAMES
      SET state = ?, version = version + 1, activePlayerId = ?, currentTurn = ?
      WHERE id = ?',
      @_);
  $self->commit;
}

sub finishGame {
  my ($self, $id) = @_;
  $self->do('
      UPDATE GAMES
      SET gstate = ?
      WHERE id = ?',
      GST_FINISH, $id);
  $self->commit;
}

sub gameWithNameExists {
  my ($self, $name, $all) = @_;
  return defined $self->fetch1('SELECT 1 FROM GAMES WHERE name = ?' . ($all ? '' : ' AND gstate <> ' . GST_EMPTY), $name);
}

sub getMap {
  my $self = shift;
  return $self->fetchrow('
      SELECT id, name, playersNum, turnsNum, regions
      FROM MAPS
      WHERE id = ?',
      $_[0]);
}

sub getGames {
  my $self = shift;
  return $self->fetchall('
      SELECT
        g.id, g.name, g.description, g.mapId, g.gstate, m.playersNum, m.turnsNum, g.activePlayerId,
        g.currentTurn,
        g.aiNum - (
          SELECT COUNT(*)
          FROM PLAYERS p
          INNER JOIN CONNECTIONS c ON c.playerId = p.id
          WHERE p.isAI = 1 AND c.gameId = g.id) AS aiNum
      FROM GAMES g INNER JOIN MAPS m ON g.mapId = m.id
      WHERE g.gstate <> ?
      ORDER BY g.id ASC',
      GST_EMPTY);
}

sub getPlayers {
  my $self = shift;
  return $self->fetchall('
      SELECT p.id, p.userName, c.isReady
      FROM PLAYERS p
      INNER JOIN CONNECTIONS c ON p.id = c.playerId
      WHERE c.gameId = ?
      ORDER by c.id',
      @_);
}

sub getGameVersion {
  my $self = shift;
  return $self->fetch1('SELECT version FROM GAMES WHERE id = ?', $_[0]);
}

sub saveCommand {
  my ($self, $gameId, $data) = @_;
  $self->do('INSERT INTO HISTORY(gameId, cmd) VALUES(?, ?)', $gameId, $data);
  $self->commit;
}

sub getHistory {
  my ($self, $gameId) = @_;
  return $self->fetchcol('SELECT cmd FROM HISTORY WHERE gameId = ?', $gameId );
}

sub getLastCmd {
  my ($self, $gameId) = @_;
  return $self->fetch1('SELECT cmd FROM HISTORY WHERE gameId = ? ORDER BY id DESC ROWS 1', $gameId);
}

sub lockGame {
  my ($self, $id) = @_;
  $self->commit;
#  $self->{dbh}->{AutoCommit} = 0;
  my $do = 0;
  do {
    eval {
      $self->{dbh}->rollback;
      $self->do('UPDATE GAMES SET id = id WHERE id = ?', $id);
      $do = 1;
      sleep 2;
    };
  } until ( $do );
}

sub unlockGame {
  my $self = shift;
  $self->{dbh}->rollback;
#  $self->{dbh}->{AutoCommit} = 1;
}


1;

__END__
