package AI::Monitor;


use strict;
use warnings;
use utf8;

use AI::Config;
use AI::Player;
use AI::Requester;


sub new {
  my $class = shift;
  my $self = {
    timeout => DEFAULT_TIMEOUT,
    @_
  };

  bless $self, $class;
  $self->_init();

  return $self;
}

sub _init {
  my $self = shift;
  $self->{req} = AI::Requester->new(%$self);
  $self->{ai} = AI::Player->new(req => $self->{req});
}

sub run {
  my $self = shift;
  while ( 1 ) {
    $self->_do();
    sleep( $self->{timeout} );
  }
}

sub _get {
  my ($self, $cmd) = @_;
  return $self->{req}->get($cmd);
}

sub _getGames {
  my $self = shift;
  my @result = grep {
    $_->{aiRequiredNum} > 0
  } @{ $self->_get('{ "action": "getGameList" }')->{games} };
  if ( defined $self->{game} ) {
    @result = grep { $_->{gameId} == $self->{game} } @result;
  }
  return @result;
}

sub _do {
  my $self = shift;
  foreach ( $self->_getGames() ) {
    $self->{ai}->do($_);
  }
}

1;

__END__
