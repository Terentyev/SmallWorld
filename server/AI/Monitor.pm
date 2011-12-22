package AI::Monitor;


use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use URI::Escape;

use AI::Config;
use AI::Player;


sub new {
  my $class = shift;
  my $self = {
    server  => DEFAULT_SERVER_ADDRESS,
    timeout => DEFAULT_TIMEOUT,
    @_
  };

  bless $self, $class;
  $self->_init();

  return $self;
}

sub _init {
  my $self = shift;
  $self->{ua} = LWP::UserAgent->new();
  $self->{ai} = AI::Player->new();
}

sub run {
  my $self = shift;
  while ( 1 ) {
    $self->_do();
    sleep( $self->{timeout} );
  }
}

sub _sendRequest {
  my ($self, $query) = @_;
  my $req = HTTP::Request->new(POST => "http://" . $self->{server} . "/");
#  $req->content_type('application/x-www-form-urlencoded');
#  $req->content('request=' . uri_escape($query));
  $req->add_content_utf8($query);
  return $self->{ua}->request($req)->content;
}

sub _get {
  my ($self, $cmd) = @_;
  return eval { $self->_sendRequest($cmd) } || {};
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
    $self->{ai}->play($_);
  }
}

1;

__END__
