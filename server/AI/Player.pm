package AI::Player;


use strict;
use warnings;
use utf8;


sub new {
  my $class = shift;
  my $self = { };

  bless $self, $class;

  return $self;
}

sub play {
  my ($self, $game) = @_;
}

1;

__END__
