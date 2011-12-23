package AI::Requester;


use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use URI::Escape;
use JSON qw( decode_json );

use AI::Config;


our $requester = undef;

sub new {
  my $class = shift;
  my $params = {
    server => DEFAULT_SERVER_ADDRESS,
    @_
  };
  if ( !defined $requester ) {
    $requester = { server => $params->{server} };

    bless $requester, $class;

    $requester->_init();
  }
  return $requester;
}

sub _init {
  my $self = shift;
  $self->{ua} = LWP::UserAgent->new();
}

sub get {
  my ($self, $cmd) = @_;
  my $req = HTTP::Request->new(POST => "http://$self->{server}/");
#  $req->content_type('application/x-www-form-urlencoded');
#  $req->content('request=' . uri_escape($cmd));
  $req->add_content_utf8($cmd);
  return eval { decode_json($self->{ua}->request($req)->content) } || {};
}

1;

__END__
