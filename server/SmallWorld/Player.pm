package SmallWorld::Player;


use strict;
use warnings;
use utf8;

# конструктор, на вход принимает ссылку на хэш с информацией о игроке
sub new {
  my $class = shift;
  my $self = shift;

  bless $self, $class;

  return $self;
}

# определяет принадлежит ли регион активной расе
sub activeConq {
  my ($self, $region) = @_;
  return defined $self->{currentTokenBadge}->{tokenBadgeId} &&
    defined $region->{tokenBadgeId} &&
    $self->{currentTokenBadge}->{tokenBadgeId} == $region->{tokenBadgeId};
}

1;

__END__
