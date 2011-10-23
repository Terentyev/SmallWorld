package SmallWorld::BaseRace;
use strict;
use warnings;
use utf8;

use SmallWorld::Consts;

# конструктор
sub new {
  my $class = shift;
  my $self = { };

  bless $self, $class;

  return $self;
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
  return 0;
}

# возвращает количество фигурок, которых теряет игрок, когда защищается
sub looseTokensBonus {
  return LOOSE_TOKENS_NUM;
}

# возвращает количество монет, которые игрок получит в конце игры
sub coinsBonus {
# TODO
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

# возвращает может ли игрок на первом завоевании завоевать эту территорию (может
# ли вообще пытаться -- типа граница и все такое)
sub canFirstConquer {
  my ($self, $region) = @_;
  return grep { $_ eq REGION_TYPE_BORDER } @{ $region->{constRegionState} };
}

# приводим расу в упадок в регионе
sub declineRegion {
  my ($self, $region) = @_;
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
  return $_[0]->BaseRace::coinsBonus() + $_[0]->getOwnedRegionsNum(REGION_TYPE_MINE);
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
  return grep {
      # регион принадлежит игроку
      $_->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} && (
        # регион граничит с регионом, на который мы нападаем
        grep { $_ == $region->{regionIdId} } $_->{adjacentRegions}
      )
    } @{ $regions }
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
  return $region->{currentBadgeState}->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} &&
    !defined $region->{holeInTheGround} &&
    $region->{conquestIdx} < 2;
}

sub canFirstConquer {
  my ($self, $region) = @_;
  # полурослики на первом завоевании могут пытаться захватить любую сушу
  return !grep { $_ eq REGION_TYPE_SEA || $_ eq REGION_TYPE_LAKE } @{ $region->{constRegionState} };
}

sub declineRegion {
  my ($self, $region) = @_;
  # у полуросликов после упадка исчезают норы
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
  return $_[0]->BaseRace::coinsBonus() + $_[0]->getOwnedRegionsNum(REGION_TYPE_FARMLAND);
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
# TODO: дописать получение дополнительных монет за захваченные территории
#  return $_[0]->BaseRace::coinsBonus() + $_[0]->getOwnedRegionsNum();
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

use SmallWorld::Consts;

sub initialTokens {
  return SKELETONS_TOKENS_NUM;
}

sub redeployTokensBonus {
  return SKELETONS_RED_TOKENS_NUM;
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
  foreach ( @{ $region->{constRegionState} } ) {
    return 1 if $_ eq REGION_TYPE_COAST;
  }
  return 0;
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
  return $region->{currentBadgeState}->{tokenBadgeId} == $player->{currentTokenBadge}->{tokenBadgeId} &&
    !defined $region->{lair};
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
  return $_[0]->getOwnedRegions(REGION_TYPE_MAGIC) + $_[0]->BaseRace::coinsBonus();
}

__END__

1;
