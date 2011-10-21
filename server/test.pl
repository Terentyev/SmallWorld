#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $tests = Tests->new();
$tests->run();

package Tests;

sub new {
  my $class = shift;
  my $self = { tests => [] };

  bless $self, $class;

  $self->load();

  return $self;
}

sub load {
  my ($self) = @_;
  foreach ( <Tests/*> ) {
    next if ! -d $_;

    my $class = $_;
    $class =~ s/(.*)\/(..)_(.*)/$1::$3/;
    push(@{$self->{tests}},  { dir => $_, class => $class }) if !@ARGV || grep { $_ == $2 } @ARGV ;
  }
}

sub run {
  my ($self) = @_;
  foreach ( @{ $self->{tests} } ) {
    $_->{obj} = eval "use $_->{class}; return $_->{class}\->new();";
    $_->{obj}->run($_->{dir});
  }

  print "\nTest is over\n\n";
  foreach ( @{ $self->{tests} } ) {
    $_->{obj}->outReport();
  }
}

__END__
