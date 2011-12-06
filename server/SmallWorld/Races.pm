package SmallWorld::BaseRace;
use strict;
use warnings;
use utf8;

use SmallWorld::Consts;

# конструктор
sub new {
  my $class = shift;
  my $self = { regions => undef, allRegions => undef };

  bless $self, $class;

  $self->_init(@_);

  return $self;
}

sub _init {
  my ($self, $regions, $badge) = @_;
  $self->{allRegions} = $regions;
  $self->{regions} = [grep {
    defined $_->{tokenBadgeId} && defined $badge->{tokenBadgeId} &&
    $_->{tokenBadgeId} == $badge->{tokenBadgeId}
  } @{ $regions }] || [];
}

# возвращает количество первоначальных фигурок для каждой расы
sub initialTokens {
  return 0;
}

# возвращает количество бонусных фигурок перед завоеваний
sub conquestTokensBonus {
  return 0;
}

# возвращает количество бонусных фигурок перед реорганизацией войск
sub redeployTokensBonus {
  my ($self, $player) = @_;
  return 0;
}

# возвращает количество фигурок, которых теряет игрок, когда защищается
sub looseTokensBonus {
  return LOOSE_TOKENS_NUM;
}

# возвращает количество бонусных монет, которые игрок получит в конце игры
sub coinsBonus {
# TODO
  return 0;
}

sub declineCoinsBonus {
  return 0;
}

# возвращает количество бонусных фигурок для атакуемого региона
sub conquestRegionTokensBonus {
  return 0;
}

# возвращает может ли игрок разместить объект в регион
sub canPlaceObj2Region {
  return 0;
}
# размещает объект в регионе
sub placeObject {
  my ($self, $player, $region) = @_;
}

# возвращает может ли игрок на первом завоевании завоевать эту территорию (может
# ли вообще пытаться -- типа граница и все такое)
sub canFirstConquer {
  my ($self, $region, $regions) = @_;
  #нельзя захватывать моря и озера
  return 0 if grep { $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE} @{ $region->{constRegionState} };
  return 1 if grep { $_ eq REGION_TYPE_BORDER } @{ $region->{constRegionState} };

  #можно захватить регион соседствующий с морем, которое является гранцией
  foreach my $i ( @{$region->{adjacentRegions}} ) {
    my ($isSea, $isBorder) = (0, 0);
    foreach ( @{$regions->[$i-1]->{constRegionState}} ){
      $isBorder = 1 if $_ eq REGION_TYPE_BORDER;
      $isSea = 1 if $_ eq REGION_TYPE_SEA;
    }
    return 1 if $isSea && $isBorder;
  }
  return 0;
}

# приводим расу в упадок в регионе
sub declineRegion {
  my ($self, $region) = @_;
}
# отказаться от региона
sub abandonRegion {
  my ($self, $region) = @_;
}

# может ли раса выполнить это действие
sub canCmd {
  my ($self, $js) = @_;
  # любая раса может выполнять любую команду кроме зачарования
  return $js->{action} ne 'enchant';
}

sub getOwnedRegionsNum {
  my ($self, $regType) = @_;
  return 1 * (grep {
    grep { $_ eq $regType } @{ $_->{constRegionState} }
  } @{ $self->{regions} });
}


package SmallWorld::RaceAmazons;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return AMAZONS_TOKENS_NUM;
}

sub conquestTokensBonus {
  return AMAZONS_CONQ_TOKENS_NUM;
}

sub redeployTokensBonus {
  return - AMAZONS_CONQ_TOKENS_NUM;
}


package SmallWorld::RaceDwarves;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return DWARVES_TOKENS_NUM;
}

sub coinsBonus {
  return $_[0]->SUPER::coinsBonus() + $_[0]->getOwnedRegionsNum(REGION_TYPE_MINE);
}

sub declineCoinsBonus {
  return $_[0]->coinsBonus();
}


package SmallWorld::RaceElves;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return ELVES_TOKENS_NUM;
}

sub looseTokensBonus {
  return ELVES_LOOSE_TOKENS_NUM;
}


package SmallWorld::RaceGiants;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return GIANTS_TOKENS_NUM;
}

sub conquestRegionTokensBonus {
  my ($self, $player, $region, $regions) = @_;
  # для гигантов бонус в 1 фигурку, если они нападают на регион, который
  # граничит с регионом, на котором находятся горы и который принадлежит
  # гигантам
  return (grep {
      # регион принадлежит игроку
      defined $_->{tokenBadgeId} && $_->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} &&
      # на нем есть горы
      (grep { $_ eq REGION_TYPE_MOUNTAIN } @{ $_->{constRegionState} }) &&
      # регион граничит с регионом, на который мы нападаем
      ( grep { defined $region->{regionId} && $_ == $region->{regionId} } @{ $_->{adjacentRegions} })
    } @{ $regions })
    ? 1
    : 0;
}


package SmallWorld::RaceHalflings;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return HALFLINGS_TOKENS_NUM;
}

sub canPlaceObj2Region {
  my ($self, $player, $region) = @_;
  return defined $region->{tokenBadgeId} && $region->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} &&
         !defined $region->{holeInTheGround} && ($player->{currentTokenBadge}->{holesPlaced} // 0) < 2;
}

sub placeObject {
  my ($self, $player, $region) = @_;
  $region->{holeInTheGround} = 1;
  ++$player->{currentTokenBadge}->{holesPlaced};
}

sub canFirstConquer {
  my ($self, $region, $regions) = @_;
  # полурослики на первом завоевании могут пытаться захватить любую сушу
  return !(grep { $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE } @{ $region->{constRegionState} });
}

# у полуросликов после упадка или отказа исчезают норы
sub declineRegion {
  my ($self, $region) = @_;
  $region->{holeInTheGround} = undef;
}

sub abandonRegion {
  my ($self, $region) = @_;
  $region->{holeInTheGround} = undef;
}


package SmallWorld::RaceHumans;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return HUMANS_TOKENS_NUM;
}

sub coinsBonus {
  return $_[0]->SUPER::coinsBonus() + $_[0]->getOwnedRegionsNum(REGION_TYPE_FARMLAND);
}


package SmallWorld::RaceOrcs;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return ORCS_TOKENS_NUM;
}

sub coinsBonus {
  # получение дополнительных монет за захваченные территории
  return $_[0]->SUPER::coinsBonus() +
    1 * (grep { defined $_->{conquestIdx} } @{ $_[0]->{regions} });
}


package SmallWorld::RaceRatmen;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return RATMEN_TOKENS_NUM;
}


package SmallWorld::RaceSkeletons;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");
use List::Util qw( min );

use SmallWorld::Consts;

sub initialTokens {
  return SKELETONS_TOKENS_NUM;
}

sub redeployTokensBonus {
  my ($self, $player) = @_;
  my $inGame = $player->{tokensInHand};
  map { $inGame += $_->{tokensNum} } @{ $self->{regions} };
  my $bonus = int ((grep { defined $_->{conquestIdx} } @{ $self->{regions} }) / 2);
  return min($bonus, SKELETONS_TOKENS_MAX -  $inGame);
}


package SmallWorld::RaceSorcerers;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return SORCERERS_TOKENS_NUM;
}

sub canCmd {
  my ($self, $js) = @_;
  # чародеи могут ещё и зачаровывать
  return $js->{action} eq 'enchant' || $self->SUPER::canCmd($js);
}


package SmallWorld::RaceTritons;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return TRITONS_TOKENS_NUM;
}

sub conquestRegionTokensBonus {
  my ($self, $player, $region, $regions) = @_;
  return (grep {
           (grep { $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE } @{ $_->{constRegionState} }) &&
           ( grep { defined $region->{regionId} && $_ == $region->{regionId} } @{ $_->{adjacentRegions} })
         } @{ $regions })
         ? 1
         : 0;
}


package SmallWorld::RaceTrolls;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return TROLLS_TOKENS_NUM;
}

sub canPlaceObj2Region {
  my ($self, $player, $region) = @_;
  return $region->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} &&
         !defined $region->{lair};
}

sub placeObject() {
  my ($self, $player, $region) = @_;
  $region->{lair} = 1;
}

sub abandonRegion {
  my ($self, $region) = @_;
  $region->{lair} = undef;
}


package SmallWorld::RaceWizards;
use strict;
use warnings;
use utf8;

use base ("SmallWorld::BaseRace");

use SmallWorld::Consts;

sub initialTokens {
  return WIZARDS_TOKENS_NUM;
}

sub coinsBonus {
  return $_[0]->getOwnedRegionsNum(REGION_TYPE_MAGIC) + $_[0]->SUPER::coinsBonus();
}


1;

__END__
