#!/usr/bin/perl
BEGIN { $| = 1 }

use strict;
use warnings;
use utf8;

use Getopt::Std;

use AI::Monitor;


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
  getopts('s:g:t:', \%result) || HELP_MESSAGE();
  renameKey('s', 'server',  \%result);
  renameKey('g', 'game',    \%result);
  renameKey('t', 'timeout', \%result);
  return %result;
}

sub HELP_MESSAGE {
  print "AI for SmallWorld game.\nUsage: $0 [[-s server_address] [-g game_id] [-t timeout_in_seconds] | [--help]]\n";
  exit(0);
}
