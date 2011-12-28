package SmallWorld::Region;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');

use SmallWorld::Consts;

our @backupNames = qw( ownerId tokenBadgeId conquestIdx prevTokenBadgeId prevTokensNum tokensNum );

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

sub calculateMinTokensCost {
  my ($self, $game, $player) = @_;

  my $race = $player->activeRace;
  my $sp = $player->activeSp;
  my @backups = ();
  if ( !defined $self->{cost} && $player->isOwned($self) ) {
    $self->{cost} = 0;
    $self->{coins} = 0;
  }
  elsif ( !defined $self->{cost} ) {
    $self->{cost} = $game->getDefendNum($player, $self, $race, $sp);
    my $dummy = [];
    @backups = $self->_tmpConquer($player, $game);
    $self->{coins} = $game->getPlayerBonus($player, $dummy);
  }
  else {
    @backups = $self->_tmpConquer($player, $game);
  }
  $race = $player->activeRace;
  $sp = $player->activeSp;

  foreach ( @{ $game->regions } ) {
    my $region = $game->getRegion(region => $_);
    # пробегаем по всем регионам и пропускаем те, на которых мы уже отметились, и
    # те, с которыми мы не граничим согласно всем правилам
    next if $player->isOwned($region) || !$sp->canAttack($region, $game->regions) || $region->isImmune;

    my $cost = $self->{cost} + $game->getDefendNum($player, $self, $race, $sp);
    my $dummy = [];
    my @backups = $region->_tmpConquer($player, $game);
    my $coins = $game->getPlayerBonus($player, $dummy);
    $region->_tmpConquerRestore(@backups);
    # TODO: сложно на данном этапе решить, что делать, если:
    #  $region->{coins} ^ $coins && $region->{cost} v $cost
    next if !defined $region->{coins} || $region->{coins} >= $coins && $region->{cost} <= $cost;

    $region->{cost} = $cost;
    $region->{coins} = $coins;
    $region->{prevRegionId} = $self->id;
    $region->calculateMinTokensCost($game, $player);
  }
  $self->_tmpConquerRestore(@backups);
}

sub _tmpConquer {
  my ($self, $player, $game) = @_;
  return () if $player->isOwned($self);
  my @result = @$self{ @backupNames };
  $self->{ownerId} = $player->id;
  $self->{prevTokenBadgeId} = $self->{tokenBadgeId};
  $self->{prevTokensNum} = $self->{tokensNum};
  $self->{tokensNum} = 1;
  $self->{tokenBadgeId} = $player->activeTokenBadgeId;
  $self->{conquestIdx} = $game->nextConquestIdx;
  return @result;
}

sub _tmpConquerRestore {
  my ($self, @backups) = @_;
  @$self{ @backupNames } = @backups if @backups;
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
