package SmallWorld::BaseSp;
use strict;
use warnings;
use utf8;

use SmallWorld::Consts;

# конструктор. В качестве параметра принимает player и regions
sub new {
  my $class = shift;
  my $self = { player => undef, regions => undef };

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
    !grep {
      $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE
    } @{ $region->{constRegionState} } &&
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
  my $js = $_->[1];
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить героев/лагеря/форты
  # или команда атаки с ненулевым числом фигурок на руках
  return $js->{action} eq 'redeploy' && !grep { defined $js->{$_} } qw( heroic encampments fortified ) ||
    $js->{action} eq 'conquer' && $_[2] >= 1;
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


package SmallWorld::SpBerserk;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

sub canCmd {
  my $js = $_->[1];
  # базовый класс + бросить кости
  return base::canCmd(@_) || $js->{action} eq 'throwDice';
}


package SmallWorld::SpBivouacking;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

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
    !grep { defined $js->{$_} } qw( heroic fortified );
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


package SmallWorld::SpDiplomat;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

sub canCmd {
  my $js = $_->[1];
  # базовый класс + подружить
  return base::canCmd(@_) || $js->{action} eq 'selectFriend';
}


package SmallWorld::SpDragonMaster;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

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
    !grep { $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE } @{ $regions };
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


package SmallWorld::SpFortified;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

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
    !grep { defined $js->{$_} } qw( heroic encampments );
}


package SmallWorld::SpHeroic;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

sub declineRegion {
  my ($self, $region) = @_;
  $region->{hero} = undef;
}

sub canCmd {
  my $js = $_->[1];
  # только команда реорганизация войск при условии, что в команде не пытаются
  # установить лагеря/форты
  return $js->{action} eq 'redeploy' &&
    !grep { defined $js->{$_} } qw( encampments fortified );
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


package SmallWorld::SpMerchant;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

sub coinsBonus {
  return 1 * grep {
    # за каждый оккупированный регион получаем по монетке
    $_->{tokensNum} > 0
  } @{ $_[0]->{regions} };
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


package SmallWorld::SpPillaging;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

sub coinsBonus {
  return 1 * grep { defined $_->{conquestIdx} } @{ $_[0]->{regions} };
}


package SmallWorld::SpSeafaring;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');

sub canAttack {
  my ($self, $region) = @_;

  return
    # можно нападать, если мы имеем регион, граничащий с регионом-жертвой
    grep {
      grep { $_ == $region->{regionId} } $_->{adjacentRegions}
    } @{ $self->{regions} };
}


package SmallWorld::SpStout;
use strict;
use warnings;
use utf8;

use base ('SmallWorld::BaseSp');


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
