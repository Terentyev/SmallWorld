package SmallWorld::Region;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');

use SmallWorld::Consts;


sub _init {
  my $self = shift;
  $self->{_game} = {@_}->{game};
  $self->{_type} = $self->_type;
}

sub buildAdjacents {
  my $self = shift;
  if ( !defined $self->_hardAdj ) {
    $self->{_hardAdj} = [];
    foreach my $r ( $self->_game->regions ) {
      next if $r->{regionId} == $self->id;
      push @{ $self->_hardAdj }, $r
        if (grep $_ == $r->{regionId}, @{ $self->{adjacentRegions} });
    }
  }
  else {
    $self->{_hardAdj} = [@{ $self->{adjacentRegions} }];
    $self->_fillAdj('hardAdj');
  }
  if ( !defined $self->_cavernAdj ) {
    $self->{_cavernAdj} = [];
    if ( $self->isCavern ) {
      foreach my $r ( $self->_game->regions ) {
        next if $r->{regionId} == $self->id;
        push @{ $self->_cavernAdj }, $r if _isTypeOf($r, REGION_TYPE_CAVERN);
      }
    }
  }
  else {
    $self->_fillAdj('cavernAdj');
  }
}

sub _fillAdj {
  my ($self, $a) = @_;
  $_ = $self->_game->getRegion(id => $_) for @{ $self->{"_$a"} };
}

sub _dropObj {
  my $self = shift;
  delete $self->{_game};
  delete $self->{_hardAdj};
  $_ = $_->{regionId} for @{ $self->_cavernAdj };
}

# возвращает количество токенов, необходимых для захвата на этот регион
sub getDefendTokensNum {
  return DEFEND_TOKENS_NUM + $_[0]->safe('fortified') +
    $_[0]->safe('encampment') +
    $_[0]->safe('lair') +
    $_[0]->safe('tokensNum') + ($_[0]->isMountain ? 1 : 0);
}

# возвращает есть ли у региона иммунитет к нападению
sub isImmune {
  my $self = shift;
  return grep $self->{$_}, qw( holeInTheGround dragon hero );
}

sub isBorder   { return $_[0]->_is(REGION_TYPE_BORDER);   }
sub isCavern   { return $_[0]->_is(REGION_TYPE_CAVERN);   }
sub isFarmLand { return $_[0]->_is(REGION_TYPE_FARMLAND); }
sub isForest   { return $_[0]->_is(REGION_TYPE_FOREST);   }
sub isHill     { return $_[0]->_is(REGION_TYPE_HILL);     }
sub isMountain { return $_[0]->_is(REGION_TYPE_MOUNTAIN); }
sub isSea      { return $_[0]->_is(REGION_TYPE_SEA);      }
sub isSwamp    { return $_[0]->_is(REGION_TYPE_SWAMP);    }

sub _is {
  my ($self, $type) = @_;
  $self->_type->{$type} = _isTypeOf($self, $type) if !defined $self->_type->{$type};
  return $self->_type->{$type};
}

# возвращает true, если в constRegionState присутствует данный тип
sub _isTypeOf {
  my ($region, $type) = @_;
  return (grep $_ eq $type, @{ $region->{constRegionState} }) ? 1 : 0;
}

sub _game        { return $_[0]->{_game};              }
sub _type        { return $_[0]->{_type} // {};        }
sub _hardAdj     { return $_[0]->{_hardAdj};           }
sub _cavernAdj   { return $_[0]->{_cavernAdj};         }
sub id           { return $_[0]->{regionId};           }
sub ownerId      { return $_[0]->{ownerId} // -1;      }
sub tokenBadgeId { return $_[0]->{tokenBadgeId} // -1; }
sub inDecline    { return $_[0]->safe('inDecline');    }
sub dragon       { return $_[0]->safe('dragon');       }
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
