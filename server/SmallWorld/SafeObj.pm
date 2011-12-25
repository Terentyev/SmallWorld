package SmallWorld::SafeObj;


use strict;
use warnings;
use utf8;

# конструктор, на вход принимает ссылку на хэш с информацией об объекте
sub new {
  my $class = shift;
  my $self = {@_}->{self};

  bless $self, $class;

  return $self;
}

# возвращает 0, если свойство неопределенно, иначе само значение свойства
sub safe {
  return defined $_[0]->{$_[1]}
    ? $_[0]->{$_[1]}
    : 0;
}

1;

__END__
