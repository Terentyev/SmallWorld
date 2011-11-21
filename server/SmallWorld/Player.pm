package SmallWorld::Player;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');

# определяет принадлежит ли регион активной расе
sub activeConq {
  my ($self, $region) = @_;
  return defined $self->{currentTokenBadge}->{tokenBadgeId} &&
    defined $region->{tokenBadgeId} &&
    $self->{currentTokenBadge}->{tokenBadgeId} == $region->{tokenBadgeId};
}

1;

__END__
