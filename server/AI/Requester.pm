package AI::Requester;


use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use URI::Escape;
use JSON qw( decode_json );

use AI::Config;
use AI::Output qw( printRequestLog );


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
  my ($self, $cmd, $add2log) = @_;
  my $req = HTTP::Request->new(POST => "http://$self->{server}/");
#  $req->content_type('application/x-www-form-urlencoded');
#  $req->content('request=' . uri_escape($cmd));
  $req->add_content_utf8($cmd);
  my $result = eval { decode_json($self->{ua}->request($req)->content) } || {};
  printRequestLog($cmd, $result) if $add2log;
  return $result;
}

1;

__END__
