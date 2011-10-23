package Tests::GameLogic;
use base ("Tests::BaseTest");


use strict;
use warnings;
use utf8;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{desc} = "Элементарные тесты игровой логики";

  bless $self, $class;

  return $self;
}

1;

__END__

