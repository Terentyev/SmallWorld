package Dispatcher;


use strict;
use warnings;
use utf8;


use Apache2::RequestRec ();
use Apache2::Request ();
use Apache2::RequestIO ();
use Apache2::Const -compile => qw(OK);

use SmallWorld::Server ();

sub handler {
  my $rr = shift;
  my $r = Apache2::Request->new($rr);
  my $rs = SmallWorld::Server->new();

  $rr->content_type('text/plain');
  $rs->process($r);

  return Apache2::Const::OK;
}

1;

__END__
