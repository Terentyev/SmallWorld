package SmallWorld::Region;


use strict;
use warnings;
use utf8;

use SmallWorld::Consts;

# конструктор, на вход принимает ссылку на хэш с информацией о регионе
sub new {
  my ($class, $self) = @_;

  bless $self, $class;

  return $self;
}

# возвращает количество токенов, необходимых для захвата на этот регион
sub getDefendTokensNum {
  return DEFEND_TOKENS_NUM + $_[0]->safe('fortified') +
    $_[0]->safe('encampment') +
    $_[0]->safe('lair') +
    $_[0]->safe('tokensNum') +
    (grep { $_ eq REGION_TYPE_MOUNTAIN } @{ $_[0]->{constRegionState} });
}

# возвращает 0, если свойство неопределенно, иначе само значение свойства
sub safe {
  return defined $_[0]->{$_[1]}
    ? $_[0]->{$_[1]}
    : 0;
}

1;

__END__
