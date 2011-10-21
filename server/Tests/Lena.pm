package Tests::Lena;
use base ("Tests::BaseTest");


use strict;
use warnings;
use utf8;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;
  $self->{desc} = "Тесты от Лены Васильевой";

  bless $self, $class;

  return $self;
}

sub getInFiles {
  return <$_[1]/*.in>;
}

1;

__END__
