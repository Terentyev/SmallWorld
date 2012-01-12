#!/usr/bin/perl

use strict;
use warnings;
use utf8;

BEGIN { $| = 1 }

use Module::Load;

my $tests = Tests->new();

$SIG{INT} = \&intHandler;

$tests->run();

sub intHandler {
  warn "Tests canceled by user\n";
  $tests->outReport();
  exit(0);
}

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
  foreach ( glob 'Tests/*'  ) {
    next if ! -d $_;

    my $class = $_;
    $class =~ s/(.*)\/(..)_(.*)/$1::$3/;
    push(@{$self->{tests}},  { dir => $_, class => $class }) if !@ARGV || grep { $_ == $2 } @ARGV ;
  }
}

sub run {
  my ($self) = @_;
  foreach ( @{ $self->{tests} } ) {
    Module::Load::load $_->{class};
    $_->{obj} = $_->{class}->new();
    $_->{obj}->run($_->{dir});
  }

  print "\nTest is over\n\n";
  $self->outReport();
}

sub outReport {
  my $self = shift;
  foreach ( @{ $self->{tests} } ) {
    last if !defined $_->{obj};
    $_->{obj}->outReport();
  }
}

__END__
