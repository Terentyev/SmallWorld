package Proxy::Server;


use strict;
use warnings;
use utf8;

use Apache2::Const -compile => qw( OK REDIRECT );
use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;

sub new {
	my $class = shift;
	my $self = { ua => LWP::UserAgent->new() };

	bless $self, $class;

	return $self;
}

sub process {
	my ($self, $r) = @_;
  my $address = $r->param('address');
  my $request = $r->param('request');

  if ( !defined $address || !defined $request )
  {
    $r->headers_out->set(Location => 'index.html');
    $r->status(Apache2::Const::REDIRECT);
    return Apache2::Const::REDIRECT;
  }

  my $req = HTTP::Request->new(POST => $address);
  $req->add_content_utf8($request);
#  $req->content_type('application/x-www-form-urlencoded');
#  $req->content("request=" . uri_escape($request)); # вот это надо раскоментировать, чтобы работало у Паши
  print $self->{ua}->request($req)->content;

  return Apache2::Const::OK;
}

1;

__END__
