package SmallWorld::BaseRace;
use strict;
use warnings;
use utf8;

use SmallWorld::Consts;

# либо ничего не принимает (например, при инициализации во время покупки расы)
# либо принимает состояние:
#  - нападающая сторона:  количество фигурок "на руках", способность
#  - принимающая сторона: идентификатор региона, на который нападают
sub new {
  my $class = shift;
  my $self = { tokensNum => 0 };

  bless $self, $class;

  $self->init(@_ || {});

  return $self;
}

# инициализация объекта
sub init {
  my ($self, $h) = @_;

  if ( !$h->{tokensNum}  ) {
    $self->{tokensNum} = $self->getInitalTokensNum();
    return;
  }

  $self->{tokensNum} = $h->{tokensNum};
  $self->{regions} = $h->{regions};
  $self->{region} = $h->{region};
  $self->{player} = $h->{player};
}

# возвращает количество первоначальных фигурок для каждой расы
sub getInitalTokensNum {
  return 0;
}

# определяет, можно ли напасть в принципе
sub canBeAttacked {
  return $_[0]->{region}->{type} eq REGION_TYPE_BORDER;
}

# определяет, может ли раса напасть без каких-либо ограничений
sub canAttackAnyway {
  return $_[0]->{player}->{power}->canAttackAnyway();
}

# предпринимаем попытку напасть
sub tryConquer {
  my ($self, $opponent) = @_;
  # если на оппонента можно напасть и количество наших фигурок больше количества
  # фигурок оппонента, то регион получилось захватить
  if ( ($self->canAttackAnyway() || $opponent->canBeAttacked()) &&
      $self->{tokensNum} > 0 &&
      $self->totalTokensForConquer( $opponent ) >= $opponent->totalTokensForDefend() ) {
    $self->conquerRegion( $opponent->looseRegion() );
    return R_ALL_OK;
  }
  return R_CANNOT_CONQUER;
}

# полное количество фигурок, которыми мы располагаем на данный момент, для
# нападения
sub totalTokensForConquer {
  return $_[0]->{tokensNum};
}

# полное количество фигурок, которые "закреплены" за данным регионам
sub totalTokensForDefend {
  return $_[0]->{tokensNum} + $_[0]->{region}->{type}->defendTokensNum();
}

# действия по окончанию хода
sub finishTurn {
  $_[0]->{player}->{coins} += $_[0]->getCoinsInEndTurn();
}

# количество регионов, которыми владеет игрок
sub getOwnedRegionsNum {
  my ($self, $regionType) = @_;
  my $res = 0;
  foreach ( @{ $self->{regions} } ) {
    ++$res if $_->{ownerId} == $_->{player}->{Id} && (!$regionType || $regionType == $_->{type});
  }
  return $res;
}

# возвращает количество монет, которые игрок получит в конце игры
sub getCoinsInEndTurn {
  return $_[0]->getOwnedRegionsNum();
}

# предварительные действия перед реорганизацией войск 
sub startRedeploy {
}

package SmallWorld::RaceAmazons;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return AMAZONS_TOKENS_NUM;
}

sub totalTokensForConquer {
  return AMAZONS_CONQ_TOKENS_NUM + $_[0]->BaseRace::totalTokensForConquer();
}


package SmallWorld::RaceDwarves;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return DWARVES_TOKENS_NUM;
}

sub getCoinsInEndTurn {
  return $_[0]->BaseRace::getCoinsInEndTurn() + $_[0]->getOwnedRegionsNum(REGION_TYPE_MINE);
}


package SmallWorld::RaceElves;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return ELVES_TOKENS_NUM;
}

sub totalTokensForDefend {
  return ELVES_DEF_TOKENS_NUM + $_[0]->BaseRace::totalTokensForDefend();
}


package SmallWorld::RaceGiants;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return GIANTS_TOKENS_NUM;
}

sub totalTokensForConquer {
  my ($self, $opponent) = @_;
  my $num = ($opponent->{region}->{type} == REGION_TYPE_MOUNTAIN )
    ? GIANTS_CONQ_TOKENS_NUM  
    : 0;
  return $num + $self->BaseRace::totalTokensForConquer();
}


package SmallWorld::RaceHalflings;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return HALFLINGS_TOKENS_NUM;
}

sub canAttackAnyway {
  return $_[0]->{turnNum} == 0 || $_[0]->BaseRace::canAttackAnyway();
}

sub canBeAttacked {
  return $_[0]->{holes} != 2 && $_[0]->BaseRace::canBeAttacked();
}


package SmallWorld::RaceHumans;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return HUMANS_TOKENS_NUM;
}

sub getCoinsInEndTurn {
  return $_[0]->BaseRace::getCoinsInEndTurn() + $_[0]->getOwnedRegionsNum(REGION_TYPE_FARMLAND);
}


package SmallWorld::RaceOrcs;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return ORCS_TOKENS_NUM;
}

sub getCoinsInEndTurn {
# TODO: дописать получение дополнительных монет за захваченные территории
#  return $_[0]->BaseRace::getCoinsInEndTurn() + $_[0]->getOwnedRegionsNum();
}


package SmallWorld::RaceRatmen;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return RATMEN_TOKENS_NUM;
}


package SmallWorld::RaceSkeletons;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return SKELETONS_TOKENS_NUM;
}

sub startRedeploy {
  $_[0]->BaseRace::startRedeploy();
# TODO: дописать получение фигурок затерритории
#$_[0]->{tokensNum} += 1;
}

package SmallWorld::RaceSorcerers;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return SORCERERS_TOKENS_NUM;
}


package SmallWorld::RaceTritons;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return TRITONS_TOKENS_NUM;
}

sub totalTokensForConquer {
  my ($self, $opponent) = @_;
  my $num = ($opponent->{region}->{type} == REGION_TYPE_MOUNTAIN )
    ? TRITONS_CONQ_TOKENS_NUM
    : 0;
  return $num + $self->BaseRace::totalTokensForConquer();
}


package SmallWorld::RaceTrolls;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return TROLLS_TOKENS_NUM;
}

sub totalTokensForDefend {
  my $num = ($_[0]->{region}->{lair})
    ? TROLLS_DEF_TOKENS_NUM
    : 0;
  return $num + $_[0]->BaseRace::totalTokensForDefend();
}


package SmallWorld::RaceWizards;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub getInitalTokensNum {
  return WIZARDS_TOKENS_NUM;
}

sub getCoinsInEndTurn {
  return $_[0]->getOwnedRegions(REGION_TYPE_MAGIC) + $_[0]->BaseRace::getCoinsInEndTurn();
}

__END__

1;
