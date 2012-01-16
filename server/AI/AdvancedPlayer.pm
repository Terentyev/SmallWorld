package AI::AdvancedPlayer;


use strict;
use warnings;
use utf8;

use base('AI::Player');

use List::Util qw( max min );

use SW::Util qw( swLog timeStart timeEnd );

use SmallWorld::Consts;

use AI::Config;
use AI::Consts;

our @backupNames = qw( ownerId tokenBadgeId conquestIdx prevTokenBadgeId prevTokensNum tokensNum );


# создает план по захвату территорий (какие регионы в каком порядке)
sub _constructConquestPlan {
  my ($self, $g, $p) = @_;
  my @ways = $self->_constructConqWays($g, $p);
  my @bonusSums = $self->_calculateBonusSums($g, 0, @ways);
  @bonusSums = $self->_calculateBonusSums($g, 1, @ways)
    if !@bonusSums && ($g->{gs}->stage ne GS_BEFORE_CONQUEST || $self->_isLastTurn($g));
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

# создает различные варианты путей захвата регионов, а также подсчитывает кол-во
# бонусных монеток и кол-во затраченных фигурок
sub _constructConqWays {
  my ($self, $g, $p) = @_;
  my $ar = $p->activeRace;
  my $asp = $p->activeSp;
  my @regions = ();
  # сначал надо определиться с регионами, с которых мы можем начать цепочки
  # завоеваний
  if ( scalar(@{ $p->regions }) == 0 ) {
    # если у игрока нет регионов, значит это первое завоевание,
    # пробегаемся по всем регионам и составляем список регионов, на которые
    # можем напасть при первом завоевании
    foreach ( @{ $g->{gs}->regions } ) {
      push @regions, $_ if $self->_canBaseAttack($g, $_->id);
    }
  }
  else {
    # у игрока есть территории, продолжаем завоевывать относительно их
    foreach my $mine ( @{ $p->regions } ) {
      foreach ( @{ $asp->getRegionsForAttack($mine) } ) {
        push @regions, $_
          if !$_->isImmune && !$p->isOwned($_) && $asp->canAttack($_) && !$g->{gs}->playerFriendWithRegionOwner($p, $_);
      }
    }
    if ( $#regions < 0 && $#{ $ar->regions } < 0 && $p->declinedTokenBadgeId ) {
      # если у игрока есть регионы, но он не может продолжать захватывать не
      # свои регионы, а мы обязаны попытаться хотя бы захватить хоть что-то,
      # нам следует захватить хотя бы регионы с расой в упадке
      foreach ( @{ $p->declinedRace->regions } ) {
        next if !$self->_canBaseAttack($g, $_->id);
        push @regions, $_;
        last;
      }
    }
  }

  # уберем повторения
  my %filter = ();
  @regions = grep { !$filter{$_->id}++ } @regions;

  my $compl = $asp->conqPlanComplexity;
  swLog(LOG_FILE, scalar (grep { $asp->canAttack($_) && !$_->isImmune } $g->{gs}->regions), $compl);
  my $maxDepth = grep { $asp->canAttack($_) && !$_->isImmune } $g->{gs}->regions;
  if ( $maxDepth > 0 && $compl > 1 ) {
    $maxDepth = log(CONQ_WAY_MAX_REGIONS_NUM / $maxDepth ) / log($compl);
  }
  swLog(LOG_FILE, "maxDepth = $maxDepth");

  my @ways = ();
  timeStart();
  push @ways, $self->_constructConqWaysForRegion($g, $p, $_, $maxDepth) for @regions;
  timeEnd(LOG_FILE, '_constructConqWaysForRegions ');
  return @ways;
}

# создает цепочку завоеваний с оценкой фигурок, которые придется потратить, и
# монет, которые получим, если пойдем таким путем
sub _constructConqWaysForRegion {
  my ($self, $g, $p, $r, $maxDepth, @wayPrefix) = @_;
  my $race = $p->activeRace;
  my $sp = $p->activeSp;
  my @backups = ();
  my @result = ();
  my %wayInfo = ( id => $r->id );
  my @way = (@wayPrefix, \%wayInfo);

  $wayInfo{cost} = $g->{gs}->getDefendNum($p, $r, $race, $sp);
  if ( $#wayPrefix >= 0 ) {
    # если регион не первый в цепочке, то к стоимости его завоевания прибавляем
    # стоимость завоевания предыдущих регионов
    $wayInfo{cost} += $wayPrefix[-1]->{cost};
  }
  my $dummy = [];
  @backups = $self->_tmpConquer($g, $p, $r);
  $wayInfo{coins} = $g->{gs}->getPlayerBonus($p, $dummy);

  if ( $self->_shouldTryConqWay($wayInfo{coins}, $#way, $maxDepth) && $wayInfo{cost} <= $p->tokens + 3 ) {
    $sp = $p->activeSp;
#    timeStart();
    foreach ( @{ $sp->getRegionsForAttack($r) } ) {
      # пробегаем по всем регионам и пропускаем те, на которых мы уже отметились, и
      # те, с которыми мы не граничим согласно всем правилам
      next if $_->isImmune || $p->isOwned($_) || !$sp->canAttack($_) || $g->{gs}->playerFriendWithRegionOwner($p, $_);

      push @result, $self->_constructConqWaysForRegion($g, $p, $_, $maxDepth, @way);
    }
#    timeEnd(LOG_FILE, (' ' x $#way) . "adjacent regions for $r->{regionId} ($wayInfo{cost})                      ");
  }
  $self->_tmpConquerRestore($r, @backups);
  return \@way if $#result < 0;
  return @result;
}

# создает оценки для каждой доступной пары раса/умение и сортирует их в порядке
# уменьшения интересности
sub _constructBadgesEstimates {
  my ($self, $g) = @_;
  my @result = ();
  my $i = 0;
  foreach ( @{ $g->{gs}->tokenBadges } ) {
    my $upRace = $self->_translateToConst($_->{raceName});
    my $upSp = $self->_translateToConst($_->{specialPowerName});
    push @result, {
      est => (
        $self->_safeGetConst("EST_$upRace") +
        $self->_safeGetConst("EST_$upSp") + 
        $self->_safeGetConst("$upRace\_TOKENS_NUM") + 
        $self->_safeGetConst("$upSp\_TOKENS_NUM") +
        $_->{bonusMoney} - $i),
      idx => $i
    };
    ++$i;
  }
  return (sort { $b->{est} <=> $a->{est} } @result);
}

# подсчитывает более детально количество монеток для цепочки завоевания
# регионов, с учетом вероятности захвата опеределенных регионов, использования
# атаки дракона
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
    # по этой цепочке нам ничего, скорее всего, не удастся завоевать
    next if $i == 0 && (
        !$self->_canDragonAttack($g) || !$self->_canEnchant($g, $_->[$i]->{id}));

    my $maxDiff = 0;
    if ( $i <= $#$_) {
      # одну фигурку мы будем обязаны оставить вместе с драконом
      $maxDiff = $self->_tryUseSpConquer($g, \$i, $_, $p, $error, 'dragonShouldAttackRegionId',
          sub { 1; }, sub { ${$_[0]} -= 1; })
        if $self->_canDragonAttack($g);
      $maxDiff = $self->_tryUseSpConquer($g, \$i, $_, $p, $error, 'enchantShouldAttackRegionId',
          sub { $self->_canEnchantOnlyRules($g, $g->{gs}->getRegion(id => $_[0])); }, sub {})
        if  $self->_canEnchant($g);
    }

    $i -= 1; # рассмотрим последний регион, который мы успешно завоюем
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
  return (sort { $b->{bonus} <=> $a->{bonus} } @bonusSums);
}

# подсчитывает уровень опасности для регионов и сортирует в порядке уменьшения
# уровня опасности
sub _calculateDangerous {
  my ($self, $g, @regions) = @_;
  my @result = ();
  my $I = $g->{gs}->getPlayer;

  my %costs = ();

  foreach ( @regions ) {
    push @result, { id => $_->id, est => 0 } if $_->isImmune;
  }
  @regions = grep !$_->isImmune, @regions;

  # промоделируем нападение каждого игрока
  foreach ( @{ $g->{gs}->players($g->{gs}->conqueror, $g->{gs}->getPlayer) } ) {
    my $p = $g->{gs}->getPlayer(player => $_);
    next if $p->id == $I->id || $p->isFriend($I);

    my @ways = $self->_constructConqWays($g, $p);
    # попытаемся найти в возможных путях нападения хоть один из интересующих нас
    # регионов
    foreach my $way ( @ways ) {
      foreach my $r ( @regions ) {
        my $wayInfo = (grep $_->{id} == $r->id, @$way)[0];
        next if !$wayInfo;
        if ( exists $costs{$r->id} ) {
          # выбираем минимальную стоимость для захвата региона
          if ( $wayInfo->{cost} < $costs{$r->id}->{cost} ) {
            $costs{$r->id}->{cost} = $wayInfo->{cost};
            $costs{$r->id}->{playerId} = $p->id;
          }
        }
        else {
          $costs{$r->id} = { cost => $wayInfo->{cost}, playerId => $p->id };
        }
        last;
      }
    }
  }

  my $max = 0;
  $max = max($max, $costs{$_}->{cost}) for keys %costs;
  $costs{$_}->{cost} = $max - $costs{$_}->{cost} + 1 for keys %costs;

  foreach ( @regions ) {
    push @result, { id => $_->id, est => 0 } if !exists $costs{$_->id};
  }

  push @result, { id => $_, est => $costs{$_}->{cost}, playerId => $costs{$_}->{playerId} } for keys %costs;
  my $sumD = 0;
  $sumD += $_->{est} for @result;
  if ( $sumD == 0 ) {
    # если для всех регионов не представляется опасности завоевания, то
    # распределяем равномерно
    $_->{est} = 1 for @result;
  }
  return (sort { $b->{est} <=> $a->{est} } @result);
}

# не нарушая никаких PBP получаем значение константы по ее имени
sub _safeGetConst {
  my ($self, $name, $default) = (@_, 0);
  my $func = UNIVERSAL::can($self, $name);
  return $func ? &$func : $default;
}

# вспомогательная функция, которая переводит название расы/умения в часть имени
# внутренней константы
sub _translateToConst {
  my ($self, $name) = @_;
  $name =~ s/^(.+)([A-Z])/$1_$2/g;
  return uc $name;
}

# временно завоёвывает регион игроком, возврщает массив предыдущий значений
# полей, которые пришлось изменить
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

# восстанавливает поля региона в состояние до временного завоевания по массиву
# данных
sub _tmpConquerRestore {
  my ($self, $r, @backups) = @_;
  @$r{ @backupNames } = @backups if @backups;
}

sub _tryUseSpConquer {
  my ($self, $g, $i, $way, $p, $error, $saveTo, $filter, $after) = (@_);
  my $maxDiff = 0;
  # будет хранить в себе индекс региона, на который применили умение для завоевания
  my $idxMaxDiff = $$i != 0 ? -1 : 0;

  # если судьба одарила нас возможностью атаковать способностью, то применим эту
  # способность на самом дорогом (в плане количества затраченных фигурок)
  # регионе
  for ( my $j = 0; $j <= $$i; ++$j ) {
    next if !&$filter($way->[$$i]->{id});
    my $diff = $way->[$j]->{cost} - ($j == 0 ? 0 : $way->[$j - 1]->{cost});
    if ( $maxDiff < $diff ) {
      $maxDiff = $diff;
      $idxMaxDiff = $j;
    }
  }
  for ( ; $$i <= $#$way; ++$$i ) {
    last if $way->[$$i]->{cost} - $maxDiff > $p->tokens + $error;
  }
  $g->{$saveTo} = $way->[$idxMaxDiff]->{id} if $idxMaxDiff != -1;

  return $maxDiff;
}

sub _getRegionsForConquest {
  my ($self, $g) = @_;
  return @{ $g->{plan} };
}

sub _getRedeployment {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer;
  my @myRegions = $p->activeRace->regions;
  my @dangerous = $self->_calculateDangerous($g, @myRegions);
  my @regions = ();
  my @heroes = ();
  my @encampments = ();
  my %fortified = ();
  my $sumD = 0;
  my $encampments = $self->_canPlaceEncampment($g) ? (ENCAMPMENTS_MAX - $self->_alienEncampNum($g)) : 0;
  my $fortifieds = $self->_canPlaceFortified($g)  ? 1 : 0;

  # собираем все токены с регионов (оставляем один только там, где иммунитет),
  # а также собираем все лагеря и героев
  foreach ( @myRegions ) {
    $p->tokens($p->tokens + $_->tokens);
    @$_{qw( hero encampment tokensNum )} = (0, 0, 0);
    if ( $_->isImmune ) {
      $p->tokens($p->tokens - 1);
      $_->tokens(1);
    }
  }

  # если игрок -- дипломат, надо выбрать самого опасного противника и
  # подружиться с ним.
  if ( $self->_canSelectFriend($g) ) {
    foreach ( @dangerous ) {
      if ( defined $_->{playerId} && $self->_canSelectFriend($g, $_->{playerId}) ) {
        $g->{shouldSelectFriendId} = $_->{playerId};
        $g->{gs}->{friendInfo} = { friendId => $_->{playerId}, diplomatId => $p->id };
        @dangerous = $self->_calculateDangerous($g, @myRegions);
        $g->{gs}->{friendInfo} = { };
        last;
      }
    }
  }

  # если игрок может ставить героев, то после расстановки героев надо ещё
  # раз подсчитать уровень опасности для регионов
  if ( $self->_canPlaceHero($g) ) {
    my $heroes = HEROES_MAX;
    foreach ( @dangerous ) {
      push @heroes, { regionId => $_->{id} };
      last if --$heroes == 0;
    }
    @dangerous = $self->_calculateDangerous($g, @myRegions);
  }

  swLog(LOG_FILE, '@dangerous', \@dangerous);
  $sumD += $_->{est} for @dangerous;
  my $n = @dangerous + 1; # количество всего наших регионов
  my $m = grep {
    $_->{est} == 0 &&
    $g->{gs}->getRegion(id => $_->{id})->tokens == 0
  } @dangerous; # количество регионов, которым не грозит опасность и на которых ещё нет фигурок
  foreach my $d ( @dangerous ) {
    $n -= 1;
    my $t = $sumD != 0 ? max(1, int(($p->tokens - $m) * $d->{est} / $sumD)) : 0;
    $sumD -= $d->{est};
    if ( $fortifieds > 0 ) {
      # можно ставить только один форт за ход
      $t = max(1, $t - 1);
      $fortified{regionId} = $d->{id};
      $fortifieds -= 1;
    }
    if ( $encampments > 0 ) {
      my $enc = max(1, int($encampments / $n));
      $t = max(1, $t - $enc);
      push @encampments, { regionId => $d->{id}, encampmentsNum => $enc };
      $encampments -= $enc;
    }
    if ( $t == 0 ) {
      $t = $g->{gs}->getRegion(id => $d->{id})->tokens;
      if ( $t != 0 ) {
        $p->tokens($p->tokens + $t);
      }
      else {
        $t = 1;
      }
    }
    push @regions, { regionId => $d->{id}, tokensNum => $t };
    last if $p->tokens($p->tokens - $t) == 0;
  }
  # все остатки, которые могли возникнуть, пихаем в самый первый регион без
  # иммунитета, потому что у него уровень опасности самый большой, а значит
  # укрепляем его
  my $r = $regions[0];
  foreach ( @regions ) {
    if ( !$g->{gs}->getRegion(id => $_->{regionId})->isImmune ) {
      $r = $_;
      last;
    }
  }
  $r->{tokensNum} += $p->tokens;
  $p->tokens(0);
  # остатки по лагерям пихаем в тот же регион
  if ( $encampments != 0 ) {
    foreach ( @encampments ) {
      next if $_->{regionId} != $r->{regionId};
      $_->{encampmentsNum} += $encampments;
      $encampments = 0;
      last;
    }
    if ( $encampments != 0 ) {
      push @encampments, { regionId => $r->{regionId}, encampmentsNum => $encampments };
      $encampments = 0;
    }
  }

  return (
      regions     => \@regions,
      encampments => (@encampments ? \@encampments : undef),
      heroes      => (@heroes ? \@heroes : undef),
      fortified   => (%fortified ? \%fortified : undef));
}

sub _beginConquest {
  my ($self, $g) = @_;
  $self->{maxCoinsForDepth} = [];
  $g->{plan} = [$self->_constructConquestPlan($g, $g->{gs}->getPlayer)];
#  die 'OK';
}

sub _endConquest {
  my ($self, $g) = @_;
  @$_{qw(cost coins prevRegionId inThread inResult)} = () for @{ $g->{gs}->regions };
  $g->{dragonShouldAttackRegionId} = undef;
  $g->{enchantShouldAttackRegionId} = undef;
  $g->{plan} = undef;
}

sub _shouldTryConqWay {
  my ($self, $coins, $depth, $maxDepth) = @_;
  return 0 if $depth >= $maxDepth ||
    ($self->{maxCoinsForDepth}->[$depth] // -1) > $coins;

  $self->{maxCoinsForDepth}->[$depth] = $coins;
  return 1;
}

sub _shouldDragonAttack {
  my ($self, $g, $regionId) = @_;
  return $regionId == ($g->{dragonShouldAttackRegionId} // $regionId);
}

sub _shouldEnchant {
  my ($self, $g, $regionId) = @_;
  return $regionId == ($g->{enchantShouldAttackRegionId} // $regionId);
}

sub _shouldStoutDecline {
  my ($self, $g) = @_;
  # ни в коем случае не приводим расу в упадок, если сейчас последний ход
  return 0 if $self->_isLastTurn($g);
  my $p = $g->{gs}->getPlayer;
  my $regions = $p->activeRace->regions;
  my $tokens = -$#$regions;
  $tokens += $_->tokens for @$regions;
  # если число фигурок, которые будут у нас в руках меньше 3 (а почему бы и не
  # 3?), то желательно привести расу в упадок, т. к. мы скорее всего ничего не
  # сможем завоевать на следующем ходу
  return $tokens <= 3;
}

sub _shouldSelectFriend {
  my ($self, $g, $playerId) = @_;
  return $playerId == $g->{shouldSelectFriendId};
}

sub _selectRace {
  my ($self, $g) = @_;
  my @estimates = $self->_constructBadgesEstimates($g);
  return $estimates[0]->{idx};
}

sub _defend {
  my ($self, $g) = @_;
  my @result = ();
  my @regions = ();
  my $p = $g->{gs}->getPlayer;
  my $ar = $p->activeRace;

  foreach ( @{ $ar->regions } ) {
    push @regions, $_ if $self->_canDefendToRegion($g, $_->id, $p, $ar);
  }

  die 'Fail defend' unless @regions;

  my @dangerous = $self->_calculateDangerous($g, @regions);
  my $sumD = 0;
  $sumD += $_->{est} for @dangerous;
  foreach ( @dangerous ) {
    next if $_->{est} == 0; # пропускаем регионы, для которых нет опасности завоевания
    my $t = max(1, int($p->tokens * $_->{est} / $sumD));
    push @result, { regionId => $_->{id}, tokensNum => $t };
    $p->tokens($p->tokens - $t);
    last if $p->tokens == 0;
  }
  $result[-1]->{tokensNum} += $p->tokens;
  $p->tokens(0);

  return \@result;
}

1;

__END__
