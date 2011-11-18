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

# инициализация объекта
sub _init {
  my ($self, $player, $regions) = @_;
  $self->{player} = $player;
  $self->{allRegions} = $regions;
  # извлекаем только свои регионы (остальные скорее всего не понадобятся)
  $self->{regions} = grep {
#    !defined $_->{tokenBadgeId} && !defined $player->{currentTokenBadge}->{tokenBadgeId} ||
    defined $_->{tokenBadgeId} && defined $player->{currentTokenBadge}->{tokenBadgeId} &&
    $_->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId}
  } @{ $regions };
}

# бонус монетками для способности
sub coinsBonus {
  return 0;
}

# можем ли мы расположить объект в регионе
sub canPlaceObj2Region {
  return 0;
}

# можем ли мы атаковать регион
sub canAttack {
  my ($self, $region) = @_;

  return
    # нельзя нападать на моря и озера
    !(grep {
      $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE
    } @{ $region->{constRegionState} }) &&
    # можно нападать, если мы имеем регион, граничащий с регионом-жертвой
    grep {
      grep { $_ == $region->{regionId} } $_->{adjacentRegions}
    } @{ $self->{regions} };
}

# возвращает количество бонусных фигурок при завоевании у оппонента
sub conquestRegionTokensBonus {
  return 0;
}

# приводим способность в упадок
sub declineRegion {
  my ($self, $region) = @_;
}

# можем ли мы с этим умением выполнить эту команду
sub canCmd {
  my $js = $_[1];
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить героев/лагеря/форты
  # или команда атаки с ненулевым числом фигурок на руках
  # или команда окончания хода с нулевым числом фигурок на руках
  # или команда выбора расы при условии, что раса не выбрана
  return ($js->{action} eq 'redeploy') && (!(grep { defined $js->{$_} } qw( heroic encampments fortified ))) ||
    ($js->{action} eq 'conquer') && (defined $_[2] && $_[2] >= 1) ||
    ($js->{action} eq 'finishTurn') && (!defined $_[2] || $_[2] == 0) ||
    ($js->{action} eq 'selectRace') && (!defined $_[2]);
}

# возвращает количество первоначальных фигурок для каждого умения
sub initialTokens {
  return 0;
}


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
  base::_init(@_);
  my ($self, $player, $regions, $badge) = @_;
  $self->{dice} = $badge->{dice} if exists $badge->{dice};
}

sub conquestRegionTokensBonus {
  return exists $_[0]->{dice} && defined $_[0]->{dice}
    ? $_[0]->{dice}
    : base::conquestRegionTokensBonus(@_);
}

sub canCmd {
  my $js = $_->[1];
  # базовый класс + бросить кости (если мы их еще не бросали)
  return base::canCmd(@_) || $js->{action} eq 'throwDice' && !exists $_[0]->{dice};
}

sub initialTokens {
  return BERSERK_TOKENS_NUM;
}


package SmallWorld::SpBivouacking;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub declineRegion {
  my ($self, $region) = @_;
  base::declineRegion(@_);
  $region->{encampment} = undef;
}

sub canCmd {
  my $js = $_->[1];
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить героев/форты
  return $js->{action} eq 'redeploy' &&
    !(grep { defined $js->{$_} } qw( heroic fortified ));
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
  my $js = $_->[1];
  # базовый класс + подружить
  return base::canCmd(@_) || $js->{action} eq 'selectFriend';
}

sub initialTokens {
  return DIPLOMAT_TOKENS_NUM;
}


package SmallWorld::SpDragonMaster;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub declineRegion {
  my ($self, $region) = @_;
  base::declineRegion(@_);
  $region->{dragon} = undef;
}

sub canCmd {
  my $js = $_->[1];
  # базовый класс + атаковать драконом
  return base::canCmd(@_) || $js->{action} eq 'dragonAttack';
}

sub initialTokens {
  return DRAGON_MASTER_TOKENS_NUM;
}


package SmallWorld::SpFlying;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub canAttack {
  my ($self, $region, $regions) = @_;
  return
    base::canAttack(@_) ||
    # если не море. Регион не обязательно должен быть соседним
    !(grep { $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE } @{ $regions });
}

sub initialTokens {
  return FLYING_TOKENS_NUM;
}


package SmallWorld::SpForest;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * grep {
    # за каждую оккупированную территорию,..
    $_->{tokensNum} > 0 &&
      # на которой расположен лес получаем по монетке
      grep { $_ eq REGION_TYPE_FOREST } $_->{constRegionState}
  } @{ $_[0]->{regions} };
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
  # за каждый форт мы получаем по дополнительной монетке
  return 1 * grep { $_->{fortified} } @{ $_[0]->{allRegions} };
}

sub declineRegion {
  my ($self, $region) = @_;
  base::declineRegion(@_);
  if ( !defined $region->{inDecline} ) {
    # видимо, если мы второй раз приводим расу в упадок после расстановки
    # фортов, то надо их удалить
    $region->{fortified} = undef;
  }
}

sub canCmd {
  my $js = $_->[1];
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить героев/лагеря
  return $js->{action} eq 'redeploy' &&
    !(grep { defined $js->{$_} } qw( heroic encampments ));
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

sub canCmd {
  my $js = $_->[1];
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить лагеря/форты
  return $js->{action} eq 'redeploy' &&
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
  return 1 * grep {
    # за каждую оккупированную территорию,..
    $_->{tokensNum} > 0 &&
      # на которой расположен холм получаем по монетке
      grep { $_ eq REGION_TYPE_HILL } $_->{constRegionState}
  } @{ $_[0]->{regions} };
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
  return 1 * grep {
    # за каждый оккупированный регион получаем по монетке
    $_->{tokensNum} > 0
  } @{ $_[0]->{regions} };
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
  return grep { $_ eq REGION_TYPE_FARMLAND || $_ eq REGION_TYPE_HILL } @{ $region->{constRegionState} }
    ? MOUNTED_CONQ_TOKENS_NUM
    : base::conquestRegionTokensBonus(@_);
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
  return 1 * grep { defined $_->{conquestIdx} } @{ $_[0]->{regions} };
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

sub canAttack {
  my ($self, $region) = @_;

  return
    # можно нападать, если мы имеем регион, граничащий с регионом-жертвой
    grep {
      grep { $_ == $region->{regionId} } $_->{adjacentRegions}
    } @{ $self->{regions} };
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

sub initialTokens {
  return STOUT_TOKENS_NUM;
}


package SmallWorld::SpSwamp;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  return 1 * grep {
    # за каждый оккупированный регион
    $_->{tokensNum} > 0 &&
      # на котором есть болота (?)
      grep { $_ eq REGION_TYPE_SWAMP } @{ $_->{constRegionState} }
  } @{ $_[0]->{regions} };
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

sub canAttack {
  my ($self, $region) = @_;

  return
    # либо мы можем атаковать регион по стандартным правилам
    base::canAttack(@_) ||
    # либо на атакуемом регионе есть природная пещера
    grep { $_ eq REGION_TYPE_CAVERN } @{ $region->{constRegionState} } &&
    # и у нас есть регион с такой же природной пещерой
    grep {
      grep { $_ eq REGION_TYPE_CAVERN } @{ $_->{consRegionState} }
    } @{ $self->{regions} };
}

sub conquestRegionTokensBonus {
  my ($self, $region) = @_;
  return
    # если атакуемый регион с пещерой (природная пещера, а не пещера тролля)
    grep { $_ eq REGION_TYPE_CAVERN } @{ $region->{constRegionState} }
      ? UNDERWORLD_CONQ_TOKENS_NUM
      : base::conquestRegionTokensBonus(@_);
}

sub initialTokens {
  return UNDERWORLD_TOKENS_NUM;
}


package SmallWorld::SpWealthy;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

use SmallWorld::Consts;

sub coinsBonus {
  my ($self, $isFirstTurn) = @_;
  die 'Stupid monkey forget pass parameter "isFirstTurn" to ' . __PACKAGE__ if !defined $isFirstTurn;
  return $isFirstTurn
    ? WEALTHY_COINS_NUM
    : base::coinsBonus(@_);
}

sub initialTokens {
  return WEALTHY_TOKENS_NUM;
}


1;

__END__
