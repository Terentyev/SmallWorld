package Tests::Protocol;
use base ("Tests::BaseTest");


use strict;
use warnings;
use utf8;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{desc} = "Элементарные тесты протокола";

  bless $self, $class;

  return $self;
}

1;

__END__
