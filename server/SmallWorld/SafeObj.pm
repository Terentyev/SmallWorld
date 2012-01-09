package SmallWorld::SafeObj;


use strict;
use warnings;
use utf8;

# конструктор, на вход принимает ссылку на хэш с информацией об объекте
sub new {
  my $class = shift;
  my $self = {@_}->{self};

  bless $self, $class;
  $self->_init(@_);

  return $self;
}

sub DropObj {
  my $o = shift;
  return unless UNIVERSAL::can($$o, 'can');
  $$o->_dropObj();
  $$o = { %$$o };
}

# различная инициализация объекта
sub _init { }

# удаляет из объекта ссылки на другие объекты
sub _dropObj { }

# возвращает 0, если свойство неопределенно, иначе само значение свойства
sub safe {
  return defined $_[0]->{$_[1]}
    ? $_[0]->{$_[1]}
    : 0;
}

1;

__END__
