package AI::AdvancedPlayer;


use strict;
use warnings;
use utf8;

use base('AI::Player');

use List::Util qw ( max min );

use SW::Util qw( swLog );

use SmallWorld::Consts;

use AI::Config;
use AI::Consts;

our @backupNames = qw( ownerId tokenBadgeId conquestIdx prevTokenBadgeId prevTokensNum tokensNum );


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
    # если у игрока нет регионов, значит это первое завоевание,
    # пробегаемся по всем регионам и составляем список регионов, на которые
    # можем напасть при первом завоевании
    foreach ( @{ $g->{gs}->regions } ) {
      my $r = $g->{gs}->getRegion(region => $_);
      push @regions, $r if $self->_canBaseAttack($g, $r->id);
    }
  }
  else {
    # у игрока есть территории, продолжаем завоевывать относительно их
    foreach ( @{ $p->regions } ) {
      my $mine = $g->{gs}->getRegion(region => $_);
      foreach ( @{ $mine->getAdjacentRegions($g->{gs}->regions, $asp) } ) {
        my $r = $g->{gs}->getRegion(region => $_);
        push @regions, $r if !$p->isOwned($r) && $self->_canBaseAttack($g, $r->id);
      }
    }
    if ( $#regions < 0 && $#{ $ar->regions } < 0 && $p->declinedTokenBadgeId ) {
      # если у игрока есть регионы, но он не может продолжать захватывать не
      # свои регионы, а мы обязаны попытаться хотя бы захватить хоть что-то,
      # нам следует захватить хотя бы регионы с расой в упадке
      foreach ( @{ $p->declinedRace->regions } ) {
        my $r = $g->{gs}->getRegion(region => $_);
        next if !$self->_canBaseAttack($g, $r->id);
        push @regions, $r;
        last;
      }
    }
  }

  my @ways = ();
  foreach ( @regions ) {
    push @ways, $self->_constructConqWays($g, $p, $g->{gs}->getRegion(region => $_));
  }

  my @bonusSums = ();
  @bonusSums = $self->_calculateBonusSums($g, 0, @ways);
  @bonusSums = $self->_calculateBonusSums($g, 1, @ways) unless @bonusSums;
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

      push @result, $self->_constructConqWays($g, $p, $region, @way);
    }
  }
  $self->_tmpConquerRestore($r, @backups);
  return \@way if $#result < 0;
  return @result;
}

sub _constructEstimates {
  my ($self, $g) = @_;
  my @result = ();
  my $i = 0;
  no strict 'refs';
  foreach ( @{ $g->{gs}->tokenBadges } ) {
    my $upRace = $self->_translateToConst($_->{raceName});
    my $upSp = $self->_translateToConst($_->{specialPowerName});
    push @result, {
      est => (
        &{"EST_$upRace"} + &{"EST_$upSp"} + &{"$upRace\_TOKENS_NUM"} + &{"$upSp\_TOKENS_NUM"} +
        $_->{bonusMoney} - $i),
      idx => $i
    };
    ++$i;
  }
  use strict 'refs';
  return sort { $b->{est} <=> $a->{est} } @result;
}

sub _calculateBonusSums {
  my ($self, $g, $force, @ways) = @_;
  my @bonusSums = ();
  my $error = $force ? 3 : 0;
  my $p = $g->{gs}->getPlayer();

  foreach ( @ways ) {
    my $i = 0;
    for ( ; $i <= $#$_; ++$i ) {
      # ищем номер региона в цепочке, на котором наше завоевание может прерваться
      last if $_->[$i]->{cost} > $p->tokens + $error;
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
      for ( ; $i <= $#$_; ++$i ) {
        last if $_->[$i]->{cost} - $maxDiff > $p->tokens + $error;
      }
    }
    $i -= 1; # рассмотрим последний регион, который мы успешно завоюем
    $g->{dragonShouldAttackRegionId} = $_->[$idxMaxDiff]->{id};
    my $bonus = $_->[$i]->{coins};
    if ( $i < $#$_ ) {
      # если в цепочке остались регионы, которые мы не захватим однозначно,
      # надо оценить сможем ли мы их захватить, бросив кубик подкрепления
      my $delta = $_->[$i + 1]->{cost} - $maxDiff - $p->tokens;
      if ( $delta ~~ [1..3] ) {
        # оценим сколько мы сможем получить бонусных монет, если рискнём завоевать
        $bonus += 1 / 6 * (3 - $delta + 1) * ($_->[$i + 1]->{coins} - $bonus);
      }
    }
    push @bonusSums, { way => $_, bonus => $bonus };
  }
  return sort { $b->{bonus} <=> $a->{bonus} } @bonusSums;
}

sub _translateToConst {
  my ($self, $name) = @_;
  $name =~ s/^(.+)([A-Z])/$1_$2/g;
  return uc $name;
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
}

sub _endConquest {
  my ($self, $g) = @_;
  @$_{qw(cost coins prevRegionId inThread inResult)} = () for @{ $g->{gs}->regions };
  $g->{dragonShouldAttackRegionId} = undef;
}

sub _shouldStoutDecline {
  my ($self, $g) = @_;
  # ни в коем случае не приводим расу в упадок, если сейчас последний ход
  return 0 if $self->_isLastTurn($g);
  my $p = $g->{gs}->getPlayer;
  my $regions = $p->activeRace->regions;
  my $tokens = -$#$regions;
  $tokens += $g->{gs}->getRegion(region => $_)->tokens for @$regions;
  # если число фигурок, которые будут у нас в руках меньше 3 (а почему бы и не
  # 3?), то желательно привести расу в упадок, т. к. мы скорее всего ничего не
  # сможем завоевать на следующем ходу
  return $tokens <= 3;
}

sub _selectRace {
  my ($self, $g) = @_;
  my @estimates = $self->_constructEstimates($g);
  return $estimates[0]->{idx};
}

1;

__END__
