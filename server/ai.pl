#!/usr/bin/perl
BEGIN { $| = 1 }

use strict;
use warnings;
use utf8;

use Getopt::Std;

use SW::Util qw( swLog );

use AI::Config;
use AI::Monitor;

BEGIN {
  $SIG{__DIE__} = \&log_die;
  $SIG{__WARN__} = \&log_warn;
}

$ENV{DEBUG} = 1;
my $monitor = AI::Monitor->new(parseArgs());
$monitor->run();

sub renameKey {
  my ($from, $to, $hash) = @_;
  if ( defined $hash->{$from} ) {
    $hash->{$to} = $hash->{$from};
    delete $hash->{$from};
  }
}

sub parseArgs {
  my %result = ();
  getopts('s:g:t:u:', \%result) || HELP_MESSAGE();
  renameKey('s', 'server',  \%result);
  renameKey('g', 'game',    \%result);
  renameKey('t', 'timeout', \%result);
  renameKey('u', 'ais',     \%result);
  return %result;
}

sub HELP_MESSAGE {
  my $s = DEFAULT_SERVER_ADDRESS;
  my $t = DEFAULT_TIMEOUT;
  print qq!
AI for SmallWorld game.
Usage: $0 [[-s server_address] [[-g game_id] [|[-u ais]] [-t timeout] | [--help]]
  -s server_address     specify server address (default server address $s)
  -g game_id            specify game id for play
  -t timeout            specify refresh timeout in seconds (default timeout $t)
  -u ais                specify AIs info (see more below)
  --help                show this information
AIs info:
  AIs info is a json with format:
    [ { "id": <id>, "sid": <sid>}, ... ]
!;
  exit(0);
}

sub log_die {
  swLog(LOG_FILE, getTime(), 'DIE', @_);
}

sub log_warn {
  swLog(LOG_FILE, getTime(), 'WARN', @_);
}

sub getTime {
  my ($s, $m, $h) = localtime();
  return "$h:$m:$s";
}
