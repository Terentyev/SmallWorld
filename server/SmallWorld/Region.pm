package SmallWorld::Region;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');

use SmallWorld::Consts;

# возвращает количество токенов, необходимых для захвата на этот регион
sub getDefendTokensNum {
  return DEFEND_TOKENS_NUM + $_[0]->safe('fortified') +
    $_[0]->safe('encampment') +
    $_[0]->safe('lair') +
    $_[0]->safe('tokensNum') +
    (grep { $_ eq REGION_TYPE_MOUNTAIN } @{ $_[0]->{constRegionState} });
}

1;

__END__
