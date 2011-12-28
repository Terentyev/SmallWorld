package SmallWorld::Region;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');

use SmallWorld::Consts;

# возвращает количество токенов, необходимых для захвата на этот регион
sub getDefendTokensNum {
  return DEFEND_TOKENS_NUM + $_[0]->safe('fortified') +
    $_[0]->safe('encampment') +
    $_[0]->safe('lair') +
    $_[0]->safe('tokensNum') +
    (grep { $_ eq REGION_TYPE_MOUNTAIN } @{ $_[0]->{constRegionState} });
}

sub getAdjacentRegions {
  my ($self, $regions, $sp) = @_;
  my @ans = ();
  foreach (@$regions) {
    push @ans, $_ if $_->{regionId} != $self->{regionId} && $sp->isAdjacent($self, $_);
  }
  return \@ans;
}

# возвращает есть ли у региона иммунитет к нападению
sub isImmune {
  my $self = shift;
  return grep $self->{$_}, qw( holeInTheGround dragon hero );
}

sub id         { return $_[0]->{regionId};         }
sub ownerId    { return $_[0]->{ownerId} // -1;    }
sub inDecline  { return $_[0]->safe('inDecline');  }
sub dragon     { return $_[0]->safe('dragon');     }
sub tokens {
  my $self = shift;
  $self->{tokensNum} = $_[0] if defined $_[0];
  return $self->safe('tokensNum');
}
sub hero {
  my $self = shift;
  $self->{hero} = $_[0] if defined $_[0];
  return $self->safe('hero');
}
sub encampment {
  my $self = shift;
  $self->{encampment} = $_[0] if defined $_[0];
  return $self->safe('encampment');
}
sub fortified {
  my $self = shift;
  $self->{fortified} = $_[0] if defined $_[0];
  return $self->safe('fortified');
}

1;

__END__
