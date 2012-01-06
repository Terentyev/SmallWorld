package AI::Output;


use strict;
use warnings;
use utf8;

use SmallWorld::Consts;
use SW::Util qw( swLog );

use AI::Config;

use base ('Exporter');
our @EXPORT_OK = qw(
    printDebug
    printGames
    printRequestLog
);

our $win = undef;
our $gamesW = undef;
our $logW = undef;
our $debugW = undef;
our @reqLog = ();

sub printGames {
  return if !win();
  $gamesW = $gamesW // $win->new(100, 80, 0, 0);
  $gamesW->clear();
  my $games = shift;
  my $top = 0;
  _printGamesHeader(\$top);
  foreach ( keys %$games ) {
    my $g = $games->{$_}->{gs};
    next if !defined $g;
    $gamesW->addstr($top, 1, $g->id);
    $gamesW->addstr($top, 5, $g->name);
    $gamesW->addstr($top, 20, $g->stage);
    $gamesW->addstr($top, 40, $g->state);
    if ( $g->state == GST_BEGIN || $g->state == GST_IN_GAME ) {
      $gamesW->addstr($top, 50, $g->getPlayer()->name);
    }
    ++$top;
    if ( scalar(@{ $g->players }) > 0 ) {
      _printPlayersHeader(\$top);
    }
    foreach ( @{ $g->players } ) {
      my $p = $g->getPlayer(player => $_);
      $gamesW->addstr($top, 4, $p->name);
      $gamesW->addstr($top, 20, $p->coins);
      $gamesW->addstr($top, 30, $p->activeRaceName . ' ' . $p->activeSpName);
      ++$top;
    }
  }
  $gamesW->refresh();
}

sub printRequestLog {
  return if !win();
  $logW = $logW // $win->new(DEFAULT_REQ_LOG_SIZE * 2, 80, 0, 82);
  my ($cmd, $res) = @_;
  swLog(LOG_FILE, { cmd => $cmd, res => $res });
  if ( scalar(@reqLog) == DEFAULT_REQ_LOG_SIZE ) {
    pop @reqLog;
  }
  unshift @reqLog, { c => $cmd, r => $res};
  my $top = 0;
  $logW->clear();
  foreach ( @reqLog ) {
    $logW->addstr($top, 0, $_->{c});
    ++$top;
    $logW->addstr($top, 20, 'result: ' . ($_->{r}->{result} // 'server error'));
    ++$top;
  }
  $logW->refresh();
}

sub printDebug {
  return if !win();
  $debugW = $debugW // $win->new(100, 80, DEFAULT_REQ_LOG_SIZE * 2 + 2, 82);
  my $msg = shift;
  $debugW->clear();
  $debugW->addstr(0, 0, $msg);
  $debugW->refresh();
}

sub _printGamesHeader {
  my $top = shift;
  $gamesW->addstr($$top, 0, '|id |');
  $gamesW->addstr($$top, 5, 'game name' . (' ' x 4) . '|');
  $gamesW->addstr($$top, 20, 'stage' . (' ' x 13) . '|');
  $gamesW->addstr($$top, 40, 'state' . (' ' x 3) . '|');
  $gamesW->addstr($$top, 50, 'active player name' . (' ' x 11) . '|');
  ++$$top;
  $gamesW->addstr($$top, 0, '-' x 80);
  ++$$top;
}

sub _printPlayersHeader {
  my $top = shift;
  $gamesW->addstr($$top, 3, '|player name' . (' ' x 4) . '|');
  $gamesW->addstr($$top, 20, 'coins |');
  $gamesW->addstr($$top, 30, 'race + power' . (' ' x 36) . '|');
  ++$$top;
  $gamesW->addstr($$top, 3, '-' x 76);
  ++$$top;
}

sub win { return eval { use Curses; $win = Curses->new() if !defined $win; return 1; } || 0; }

END {
  endwin();
}

1;

__END__
