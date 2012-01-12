#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Perl::Critic;

my $critic = Perl::Critic->new();
while ( my $f = shift ) {
  print "Critique a file $f\n";
  my @violations = $critic->critique($f);
  print @violations;
}
