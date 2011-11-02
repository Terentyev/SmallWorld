package Dispatcher;


use strict;
use warnings;
use utf8;


use Apache2::RequestRec ();
use Apache2::Request ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

use SmallWorld::Server ();

our $server = undef;

sub getServer {
  if ( !defined $server ) {
    $server = SmallWorld::Server->new();
  }
  return $server;
}

sub handler {
  my $rr = shift;
  my $r = Apache2::Request->new($rr);

  $rr->content_type('text/plain');
  getServer()->process($r);

  return Apache2::Const::OK;
}

1;

__END__
