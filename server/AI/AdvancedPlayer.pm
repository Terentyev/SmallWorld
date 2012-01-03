package AI::AdvancedPlayer;


use strict;
use warnings;
use utf8;

use base('AI::Player');

use List::Util qw ( max );

use SW::Util qw( swLog );

use AI::Config;

our @backupNames = qw( ownerId tokenBadgeId conquestIdx prevTokenBadgeId prevTokensNum tokensNum );


sub _saveState {
  my ($self, $g, $state) = @_;
  return $self->SUPER::_saveState($g, $state);
  $state->{plan} = [];
  foreach ( @{ $g->{plan} // [] } ) {
    my $r = $g->{gs}->getRegion(region => $_);
    my $p = {};
    $p->{$_} = $r->{$_} for qw( regionId cost coins prevRegionId inThread inResult );
    push @{ $state->{plan} }, $p;
  }
  $state->{$_} = $g->{$_} for qw( dragonShouldAttackRegionId );
}

sub _loadState {
  my ($self, $g, $state) = @_;
  return $self->SUPER::_loadState($g, $state);
  $g->{plan} = [];
  foreach my $p ( @{ $state->{plan} // [] } ) {
    my $r = $g->{gs}->getRegion(id => $p->{regionId});
    $r->{$_} = $p->{$_} for qw( cost coins prevRegionId inThread inResult );
    push @{ $g->{plan} }, $r;
  }
  $g->{$_} = $state->{$_} for qw( dragonShouldAttackRegionId );
}

sub _shouldDragonAttack {
  my ($self, $g, $regionId) = @_;
  return !defined $g->{dragonShouldAttackRegionId} || $regionId == $g->{dragonShouldAttackRegionId};
}

sub _constructConquestPlan {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer;
  my $ar = $p->activeRace;
  my $asp = $p->activeSp;
  my @regions = ();
  if ( scalar(@{ $p->regions }) == 0 ) {
    foreach ( @{ $g->{gs}->regions } ) {
      my $r = $g->{gs}->getRegion(region => $_);
      push @regions, $r if $self->_canBaseAttack($g, $r->id);
    }
  }
  else {
    foreach ( @{ $p->regions } ) {
      my $mine = $g->{gs}->getRegion(region => $_);
      foreach ( @{ $mine->getAdjacentRegions($g->{gs}->regions, $asp) } ) {
        my $r = $g->{gs}->getRegion(region => $_);
        push @regions, $r if !$p->isOwned($r) && $self->_canBaseAttack($g, $r->id);
      }
    }
  }

  my @ways = ();
  foreach ( @regions ) {
    push @ways, $self->_constructConqWays($g, $p, $g->{gs}->getRegion(region => $_));
  }

  swLog(LOG_FILE, \@ways);

  my @bonusSums = ();
  foreach ( @ways ) {
    my $i = 0;
    for ( ; $i <= $#$_ + 1; ++$i ) {
#      # ищем номер региона в цепочке, на котором наше завоевание прервется
#      last if $i > $#$_ || $_->[$i]->{cost} > $p->tokens + 3;
      # ищем номер региона в цепочке, на котором наше завоевание может прерваться
      last if $i > $#$_ || $_->[$i]->{cost} > $p->tokens;
    }
    next if $i == 0 && !$self->_canDragonAttack($g); # по этой цепочке нам ничего, скорее всего, не удастся завоевать

    my $maxDiff = 0;
    my $idxMaxDiff = $i != 0 ? -1 : 0; # будет хранить в себе индекс региона, на который должен напасть дракон
    if ( $i <= $#$_ && $self->_canDragonAttack($g) ) {
      # если судьба одарила нас возможностью атаковать драконом, то применим эту
      # способность на самом дорогом (в плане количества затраченных фигурок)
      # регионе
      for ( my $j = 0; $j <= $i ; ++$j ) {
        my $diff = $_->[$j]->{cost} - ($j == 0 ? 0 : $_->[$j - 1]->{cost});
        if ( $maxDiff < $diff ) {
          $maxDiff = $diff;
          $idxMaxDiff = $j;
        }
      }
      $maxDiff -= 1; # одну фигурку мы будем обязаны оставить вместе с драконом
      for ( $i += 1; $i <= $#$_ + 1; ++$i ) {
        last if $i > $#$_ || $_->[$i]->{cost} - $maxDiff > $p->tokens + 3;
      }
    }
    $g->{dragonShouldAttackRegionId} = $_->[$idxMaxDiff]->{id};
    my $bonus = $_->[$i]->{coins};
    my $delta = $_->[$i]->{cost} - $maxDiff - $p->tokens;
    if ( $i <= $#$_ && $delta ~~ [1..3] ) {
      # оценим сколько мы сможем получить бонусных монет, если рискнём завоевать
      $bonus += 1 / 6 * (3 - $delta + 1) * ($_->[$i]->{coins} - $bonus);
    }
    push @bonusSums, { way => $_, bonus => $bonus };
  }
  @bonusSums = sort { $b->{bonus} <=> $a->{bonus} } @bonusSums;
  swLog(LOG_FILE, "Bonus sums", \@bonusSums);

  # формируем массив регионов по порядку их завоевания
  my @result = ();
  foreach my $bs( @bonusSums ) {
    foreach ( @{ $bs->{way} } ) {
      my $r = $g->{gs}->getRegion(id => $_->{id});
      push @result, $r if !$r->{inResult};
      $r->{inResult} = 1;
    }
  }
  return @result;
}

sub _constructConqWays {
  my ($self, $g, $p, $r, @wayPrefix) = @_;
  my $race = $p->activeRace;
  my $sp = $p->activeSp;
  my @backups = ();
  my @result = ();
  my %wayInfo = ( id => $r->id );
  my @way = (@wayPrefix, \%wayInfo);

  $wayInfo{cost} = $g->{gs}->getDefendNum($p, $r, $race, $sp);
  if ( $#wayPrefix >= 0 ) {
    $wayInfo{cost} += $wayPrefix[-1]->{cost};
  }
  my $dummy = [];
  @backups = $self->_tmpConquer($g, $p, $r);
  $wayInfo{coins} = $g->{gs}->getPlayerBonus($p, $dummy);
  $race = $p->activeRace;
  $sp = $p->activeSp;

  if ( $wayInfo{cost} <= $p->tokens + 3 ) {
    foreach ( @{ $r->getAdjacentRegions($g->{gs}->regions, $sp) } ) {
      my $region = $g->{gs}->getRegion(region => $_);
      # пробегаем по всем регионам и пропускаем те, на которых мы уже отметились, и
      # те, с которыми мы не граничим согласно всем правилам
      next if $p->isOwned($region) || !$sp->canAttack($region, $g->{gs}->regions) || $region->isImmune;

      swLog(LOG_FILE, (" " x $#way) . "Enter to $region->{regionId}");
      push @result, $self->_constructConqWays($g, $p, $region, @way);
      swLog(LOG_FILE, (" " x $#way) . "leave from $region->{regionId}");
    }
  }
  $self->_tmpConquerRestore($r, @backups);
  return \@way if $#result < 0;
  return @result;
}

sub _tmpConquer {
  my ($self, $g, $p, $r) = @_;
  return () if $p->isOwned($r);
  my @result = @$r{ @backupNames };
  $r->{ownerId} = $p->id;
  $r->{prevTokenBadgeId} = $r->{tokenBadgeId};
  $r->{prevTokensNum} = $r->{tokensNum};
  $r->{tokensNum} = 1;
  $r->{tokenBadgeId} = $p->activeTokenBadgeId;
  $r->{conquestIdx} = $g->{gs}->nextConquestIdx;
  return @result;
}

sub _tmpConquerRestore {
  my ($self, $r, @backups) = @_;
  @$r{ @backupNames } = @backups if @backups;
}

sub _getRegionsForConquest {
  my ($self, $g) = @_;
  return @{ $g->{plan} };
}

sub _beginConquest {
  my ($self, $g) = @_;
  $g->{plan} = [$self->_constructConquestPlan($g)];
  swLog(LOG_FILE, $g->{plan});
}

sub _endConquest {
  my ($self, $g) = @_;
  @$_{qw(cost coins prevRegionId inThread inResult)} = () for @{ $g->{gs}->regions };
  $g->{dragonShouldAttackRegionId} = undef;
}

1;

__END__
