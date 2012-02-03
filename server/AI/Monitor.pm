package AI::Monitor;


use strict;
use warnings;
use utf8;
use Switch;

use AI::AdvancedPlayer;
use AI::AdvancedPlayerSE;
use AI::Config;
use AI::Player;
use AI::Requester;


sub new {
  my $class = shift;
  my $self = { timeout => DEFAULT_TIMEOUT };

  bless $self, $class;
  $self->_init(@_);

  return $self;
}

sub _init {
  my $self = shift;
  my %p = (@_);
  $self->{req} = AI::Requester->new(%p);
  $p{req} = $self->{req};
  $p{level} //= 2;
  switch ($p{level}) {
    case 0 { $self->{ai} = AI::Player->new(%p) }
    case 1 { $self->{ai} = AI::AdvancedPlayer->new(%p) }
    else { $self->{ai} = AI::AdvancedPlayerSE->new(%p) }
  }
  $self->{game} = $p{game};
}

sub run {
  my $self = shift;
  while ( 1 ) {
    $self->_do();
    $self->_printStatus();
    sleep( $self->{timeout} );
  }
}

sub _get {
  my ($self, $cmd) = @_;
  return $self->{req}->get($cmd);
}

sub _getGames {
  my $self = shift;
  my @result = @{ $self->_get('{ "action": "getGameList" }')->{games} // [] };
  if ( defined $self->{game} ) {
    @result = grep { $_->{gameId} == $self->{game} } @result;
  }
  return @result;
}

sub _do {
  my $self = shift;
  foreach ( $self->_getGames() ) {
    $self->ai->do($_);
  }
}

sub _printStatus {
  my $self = shift;
  $self->ai->printStatus();
}

sub ai { return $_[0]->{ai}; }

1;

__END__
