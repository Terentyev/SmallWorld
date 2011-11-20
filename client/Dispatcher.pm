package Dispatcher;


use strict;
use warnings;
use utf8;


use Apache2::RequestRec ();
use Apache2::Request ();
use Apache2::RequestIO ();

use Proxy::Server ();

our $server = undef;

sub getServer {
  if ( !defined $server ) {
    $server = Proxy::Server->new();
  }
  return $server;
}

sub handler {
  my $rr = shift;
  my $r = Apache2::Request->new($rr);

  $rr->content_type('text/plain');
  return getServer()->process($r);
}

1;

__END__
