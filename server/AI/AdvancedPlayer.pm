package AI::AdvancedPlayer;


use strict;
use warnings;
use utf8;

use base('AI::Player');

use List::Util qw ( max );

use SW::Util qw( swLog );

use AI::Config;


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
  my @regions = @{ $p->regions };
  if ( scalar(@regions) == 0 ) {
    foreach ( @{ $g->{gs}->regions } ) {
      my $r = $g->{gs}->getRegion(region => $_);
      push @regions, $r if $self->_canBaseAttack($g, $r->id);
    }
  }

  foreach ( @regions ) {
    $g->{gs}->getRegion(region => $_)->calculateMinTokensCost($g->{gs}, $p);
  }

  # сортируем массим регионов в порядке убывания по количеству монеток, что мы
  # за них получим пройдя по цепочке
  my @sorted = sort { $b->{coins} <=> $a->{coins} } grep defined $_->{cost}, @{ $g->{gs}->regions };
  # формируем цепочки возможных завоеваний (если идти по порядку массива sorted,
  # то нам сначала будут попадаться концы цепочек, начиная с них мы и
  # восстанавливаем цепочкм
  my @threads = ();
  foreach ( @sorted ) {
    # если мы регион уже добавили в цепочку, то пропускаем его
    next if $_->{inThread};
    my @thread = ();
    my $r = $_;
    # добавляем регион в цепочку в начало цепочки и переходим к следующему
    # региону в цепочке по ссылке prevRegionId
    do {
      $r->{inThread} = 1;
      unshift @thread, $r;
    } while ( $r = $g->{gs}->getRegion(id => $r->{prevRegionId}) );
    push @threads, \@thread;
  }

  my @bonusSums = ();
  foreach ( @threads ) {
    my $i = 0;
    for ( ; $i <= $#$_ + 1; ++$i ) {
      # ищем номер региона в цепочке, на котором наше завоевание прервется
      last if $i > $#$_ || $_->[$i]->{cost} > $p->tokens + 3;
    }
    next if $i == 0 && !$self->_canDragonAttack($g); # по этой цепочке нам ничего не удастся завоевать

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
    $g->{dragonShouldAttackRegionId} = $_->[$idxMaxDiff]->{regionId};
    $i -= 1; # до этого $i обозначал индекс региона, который нам не удастся захватить
    my $bonus = $_->[$i]->{coins};
    my $delta = $_->[$i]->{cost} - $maxDiff - $p->tokens;
    if ( $i <= $#$_ && $delta ~~ [1..3] ) {
      # оценим сколько мы сможем получить бонусных монет, если рискнём завоевать
      $bonus += 1 / 6 * (3 - $delta + 1) * ($_->[$i]->{coins} - $bonus);
    }
    push @bonusSums, { thread => $_, bonus => $bonus };
  }
  @bonusSums = sort { $b->{bonus} <=> $a->{bonus} } @bonusSums;

  # формируем массив регионов по порядку их завоевания
  my @result = ();
  foreach my $bs( @bonusSums ) {
    foreach my $r ( @{ $bs->{thread} } ) {
      push @result, $r if !$r->{inResult} && ($_->{ownerId} // -1) != $p->id;
      $r->{inResult} = 1;
    }
  }
  # добавим в массив регионов также все остальные не наши регионы
  foreach ( @{ $g->{gs}->regions } ) {
    push @result, $_ if !$_->{inResult} && ($_->{ownerId} // -1) != $p->id;
  }
  return @result;
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
