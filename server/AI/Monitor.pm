package AI::Monitor;


use strict;
use warnings;
use utf8;

use AI::AdvancedPlayer;
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
  $self->{ai} = $p{simple}
    ? AI::Player->new(%p)
    : AI::AdvancedPlayer->new(%p);
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
