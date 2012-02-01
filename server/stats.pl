#!/usr/bin/perl


use utf8;
use warnings;
use strict;


die 'Specify input file, please' if !@ARGV;

open FILE, '<', $ARGV[0] or die "Can not open file '$ARGV[0]'";
my ($wins, $fails, $games, $coins1, $coins2) = (0, 0, 0, 0, 0);
while ( 1 ) {
  my $first = <FILE>;
  my $second = <FILE>;
  last if !$first || !$second;

  foreach ( \$first, \$second ) {
    if ( $$_ =~ m/"coins":(\d+)/ ) {
      $$_ = $1;
    }
    else {
      die "Can not extract coins in line '$$_'";
    }
  }
  $coins1 += $first;
  $coins2 += $second;
  if ( $first > $second ) {
    ++$wins;
  }
  elsif ( $first < $second ) {
    ++$fails;
  }
  ++$games;
}
close FILE;

$coins1 = $coins1 / $games;
$coins2 = $coins2 / $games;

print "
Games:       $games
First wins:  $wins
Second wins: $fails
First average coins:  $coins1
Second average coins: $coins2
";
