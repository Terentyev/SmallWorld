package SmallWorld::BaseSp;
use strict;
use warnings;
use utf8;

use SmallWorld::Consts;

# конструктор. В качестве параметра принимает player и regions
sub new {
  my $class = shift;
  my $self = { player => undef, regions => undef, allRegions => undef };

  bless $self, $class;

  $self->_init(@_);

  return $self;
}

sub DESTROY {
  my $self = shift;
  delete $self->{player};
  delete $self->{regions};
  delete $self->{allRegions};
}

# инициализация объекта
sub _init {
  my ($self, $player, $state) = @_;
  $self->{player} = $player;
  $self->{allRegions} = $state->regions;
  # извлекаем только свои регионы (остальные скорее всего не понадобятся)
  $self->{regions} = [grep { $player->activeConq($_) } $state->regions] || [];
}

# бонус монетками для способности
sub coinsBonus {
  return 0;
}

# можем ли мы расположить объект в регионе
sub canPlaceObj2Region {
  return 0;
}

sub canFirstConquer {
  my ($self, $region) = @_;
  return 0;
}

# можем ли мы атаковать регион
sub canAttack {
  my ($self, $region) = @_;
  # нельзя нападать на моря и озера
  return !$region->isSea;
}

# возвращает количество бонусных фигурок при завоевании у оппонента
sub conquestRegionTokensBonus {
  return 0;
}

# приводим способность в упадок
sub declineRegion {
  my ($self, $region) = @_;
}

# отказаться от региона
sub abandonRegion {
  my ($self, $region) = @_;
}

# можем ли мы с этим умением выполнить эту команду
sub canCmd {
  my ($self, $js, $state, $player) = @_;
  return ! ( $js->{action} eq 'redeploy' && (grep { defined $js->{$_} } qw( heroes encampments fortified )) ||
             $js->{action} eq 'throwDice' || $js->{action} eq 'dragonAttack' || $js->{action} eq 'selectFriend' ||
             $js->{action} eq 'decline' && $state eq GS_BEFORE_FINISH_TURN
           );
}

# возвращает количество первоначальных фигурок для каждого умения
sub initialTokens {
  return 0;
}

# возвращает список регионов, которые граничат с данным регионом
sub getAdjacentRegions {
  my ($self, $region) = @_;
  return $region->_hardAdj;
}

# возвращаеь список регионов, на которые можем напасть с данного региона
sub getRegionsForAttack {
  my ($self, $region) = @_;
  return $self->getAdjacentRegions($region);
}

sub activate {
  my ($self, $state, $player) = @_;
}

#сбрасывает флаги использования спец умения в конце хода
sub finishTurn {
  my ($self, $state) = @_;
  return 0;
}

sub conqPlanComplexity {
  my $self = shift;
  my $result = 0;
  my $n = 0;
  foreach ( $self->allRegions ) {
    next if $self->player->isOwned($_) || !$self->canAttack($_) || $_->isImmune;
    $result += scalar (grep { $self->canAttack($_) && !$self->player->isOwned($_) && !$_->isImmune } @{ $self->getAdjacentRegions($_) });
    ++$n;
  }
  return $result / $n;
}

sub player     { return $_[0]->{player};                                            }
sub regions    { return wantarray ? @{ $_[0]->{regions} } : $_[0]->{regions};       }
sub allRegions { return wantarray ? @{ $_[0]->{allRegions} } : $_[0]->{allRegions}; }

package SmallWorld::SpAlchemist;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return ALCHEMIST_COINS_BONUS;
}

sub initialTokens {
  return ALCHEMIST_TOKENS_NUM;
}


package SmallWorld::SpBerserk;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub _init {
  my ($self, $player, $state, $badge) = @_;
  $self->SUPER::_init($player, $state, $badge);
  $self->{dice} = $state->berserkDice;
}

sub conquestRegionTokensBonus {
  my ($self, $region) = @_;
  return defined $self->{dice}
    ? $self->{dice}
    : $self->SUPER::conquestRegionTokensBonus($region);
}

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # базовый класс + бросить кости (если мы их еще не бросали)
  return $self->SUPER::canCmd($js, $state, $player) ||
         $js->{action} eq 'throwDice' && !defined $self->{dice} && $player->{tokensInHand};
}

sub initialTokens {
  return BERSERK_TOKENS_NUM;
}

sub activate {
  my ($self, $state, $player) = @_;
  $state->{berserkDice} = undef;
}

sub finishTurn {
  my ($self, $state) = @_;
  $state->{berserkDice} = undef;
}


package SmallWorld::SpBivouacking;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub declineRegion {
  my ($self, $region) = @_;
  $self->SUPER::declineRegion($region);
  $region->{encampment} = undef;
}

sub abandonRegion {
  my ($self, $region) = @_;
  $region->{encampment} = undef;
}

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить героев/форты
  return $self->SUPER::canCmd($js, $state, $player) || $js->{action} eq 'redeploy' &&
    !(grep { defined $js->{$_} } qw( heroes fortified ));
}

sub initialTokens {
  return BIVOUACKING_TOKENS_NUM;
}


package SmallWorld::SpCommando;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub conquestRegionTokensBonus {
  return COMMANDO_CONQ_TOKENS_NUM;
}

sub initialTokens {
  return COMMANDO_TOKENS_NUM;
}


package SmallWorld::SpDiplomat;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # базовый класс + подружить
  return $self->SUPER::canCmd($js, $state, $player) || $js->{action} eq 'selectFriend';
}

sub initialTokens {
  return DIPLOMAT_TOKENS_NUM;
}

sub activate {
  my ($self, $state, $player) = @_;
  $state->{friendInfo} = {
    'diplomatId' => $player->{playerId},
    'friendId' => undef
  };
}


package SmallWorld::SpDragonMaster;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub _init {
  my ($self, $player, $state, $badge) = @_;
  $self->SUPER::_init($player, $state, $badge);
  $self->{dragonAttacked} = $state->dragonAttacked;
}

sub declineRegion {
  my ($self, $region) = @_;
  $self->SUPER::declineRegion($region);
  $region->{dragon} = undef;
}

sub abandonRegion {
  my ($self, $region) = @_;
  $region->{dragon} = undef;
}

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # базовый класс + атаковать драконом
  return $self->SUPER::canCmd($js, $state, $player) || ($js->{action} eq 'dragonAttack') && !$self->{dragonAttacked};
}

sub initialTokens {
  return DRAGON_MASTER_TOKENS_NUM;
}

sub activate {
  my ($self, $state, $player) = @_;
  $state->{dragonAttacked} = 0;
}

sub finishTurn {
  my ($self, $state) = @_;
  $state->{dragonAttacked} = 0;
}


package SmallWorld::SpFlying;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub initialTokens {
  return FLYING_TOKENS_NUM;
}

sub getRegionsForAttack {
  my ($self, $region) = @_;
  return $self->{allRegions};
}


package SmallWorld::SpForest;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * (grep {
    # за каждую оккупированную территорию,..
    $_->{tokensNum} > 0 &&
      # на которой расположен лес получаем по монетке
      $_->isForest
  } $_[0]->regions);
}

sub initialTokens {
  return FOREST_TOKENS_NUM;
}


package SmallWorld::SpFortified;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  # за каждый форт мы получаем по дополнительной монетке если раса активна
  return 1 * (grep { $_->{fortified} } $_[0]->regions);
}

sub abandonRegion {
  my ($self, $region) = @_;
  $region->{fortified} = undef;
}

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить героев/лагеря
  return $self->SUPER::canCmd($js, $state, $player) || $js->{action} eq 'redeploy' &&
    !(grep { defined $js->{$_} } qw( heroes encampments ));
}

sub initialTokens {
  return FORTIFIED_TOKENS_NUM;
}


package SmallWorld::SpHeroic;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub declineRegion {
  my ($self, $region) = @_;
  $region->{hero} = undef;
}

sub abandonRegion {
  my ($self, $region) = @_;
  $region->{hero} = undef;
}

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить лагеря/форты
  return $self->SUPER::canCmd($js, $state, $player) || $js->{action} eq 'redeploy' &&
    !(grep { defined $js->{$_} } qw( encampments fortified ));
}

sub initialTokens {
  return HEROIC_TOKENS_NUM;
}


package SmallWorld::SpHill;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * (grep {
    # за каждую оккупированную территорию,..
    $_->{tokensNum} > 0 &&
      # на которой расположен холм получаем по монетке
      $_->isHill
  } $_[0]->regions);
}

sub initialTokens {
  return HILL_TOKENS_NUM;
}


package SmallWorld::SpMerchant;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * (grep {
    # за каждый оккупированный регион получаем по монетке
    $_->{tokensNum} > 0
  } $_[0]->regions);
}

sub initialTokens {
  return MERCHANT_TOKENS_NUM;
}


package SmallWorld::SpMounted;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub conquestRegionTokensBonus {
  my ($self, $region) = @_;
  return ($region->isHill || $region->isFarmLand)
    ? MOUNTED_CONQ_TOKENS_NUM
    : $self->SUPER::conquestRegionTokensBonus($region);
}

sub initialTokens {
  return MOUNTED_TOKENS_NUM;
}


package SmallWorld::SpPillaging;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * (grep { defined $_->{conquestIdx} && $_->{prevTokensNum}} $_[0]->regions);
}

sub initialTokens {
  return PILLAGING_TOKENS_NUM;
}


package SmallWorld::SpSeafaring;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub canFirstConquer {
  my ($self, $region) = @_;
  #можно любой пограничный регион
  return $region->isBorder;
}

sub canAttack {
  my ($self, $region) = @_;
  # даже если море
  return 1;
}

sub initialTokens {
  return SEAFARING_TOKENS_NUM;
}


package SmallWorld::SpStout;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub canCmd {
  my ($self, $js, $state, $player) = @_;
  # команда decline после реорганизации войск
  return $self->SUPER::canCmd($js, $state, $player) || $js->{action} eq 'decline' && $state eq GS_BEFORE_FINISH_TURN;
}

sub initialTokens {
  return STOUT_TOKENS_NUM;
}

sub activate {
  my ($self, $state, $player) = @_;
  $state->{stoutStatistics} = undef;
}


package SmallWorld::SpSwamp;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * (grep {
    # за каждый оккупированный регион
    $_->{tokensNum} > 0 &&
      # на котором есть болота (?)
      $_->isSwamp
  } $_[0]->regions);
}

sub initialTokens {
  return SWAMP_TOKENS_NUM;
}


package SmallWorld::SpUnderworld;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;
use SmallWorld::Utils qw( mergeArrays );

sub conquestRegionTokensBonus {
  my ($self, $region) = @_;
  return
    # если атакуемый регион с пещерой (природная пещера, а не пещера тролля)
    $region->isCavern
      ? UNDERWORLD_CONQ_TOKENS_NUM
      : $self->SUPER::conquestRegionTokensBonus($region);
}

sub initialTokens {
  return UNDERWORLD_TOKENS_NUM;
}

sub getAdjacentRegions {
  my ($self, $region) = @_;
  return mergeArrays($region->_hardAdj, $region->_cavernAdj);
}


package SmallWorld::SpWealthy;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  my ($self, $state) = @_;
  return !$state->{gotWealthy} ? WEALTHY_COINS_NUM: $self->SUPER::coinsBonus($state);
}

sub activate {
  my ($self, $state, $player) = @_;
  $state->{gotWealthy} = 0;
}

sub finishTurn {
  my ($self, $state) = @_;
  $state->{gotWealthy} = 1;
}

sub initialTokens {
  return WEALTHY_TOKENS_NUM;
}


1;

__END__
