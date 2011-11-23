package Proxy::Server;


use strict;
use warnings;
use utf8;

use Apache2::Const -compile => qw( OK REDIRECT );
use APR::Request::Param;
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
  my $req = undef;
  my $result = Apache2::Const::OK;

  if ( $r->uri() eq '/upload_map' ) {
    $result = $self->proxyUpload($r);
  }
  else {
    $result = $self->proxyCommand($r);
  }

  print $self->{ua}->request($req)->content if $result eq Apache2::Const::OK;

  return $result;
}

sub redirect {
  my ($self, $r) = @_;
  $r->headers_out->set(Location => 'index.html');
  $r->status(Apache2::Const::REDIRECT);
  return Apache2::Const::REDIRECT;
}

sub proxyCommand {
  my ($self, $r) = @_;
  my $address = $r->param('address');
  my $request = $r->param('request');

  if ( !defined $address || !defined $request )
  {
    return $self->redirect($r);
  }

  $r = HTTP::Request->new(POST => $address);
  $r->add_content_utf8($request);
#  $r->content_type('application/x-www-form-urlencoded');
#  $r->content("request=" . uri_escape($request)); # вот это надо раскоментировать, чтобы работало у Паши
  return Apache2::Const::OK;
}

sub proxyUpload {
  my ($self, $r) = @_;
  my $body = $r->upload('filename');

  if ( !defined $body || !defined $r->param('mapId') || !defined $r->param('address') ) {
    return $self->redirect($r);
  }

  my $ext = ($body->upload_filename() =~ m/.*(\..+)$/)[0];

  if ( !defined $ext || $ext !~ m/^\.(png|jpeg|jpg)$/ ) {
    return $self->redirect($r);
  }

  my $filen = $body->upload_fh();
  $r = HTTP::Request::StreamingUpload->new(
      POST         => $r->param('address'),
      fh           => $filen,
      headers      => HTTP::Header->new(
        'Content-Length' => -s $filen
      ),
      Content_Type => 'multipart/form-data',
      Content      => [ mapId => $r->param('mapId') ]
  );
  return Apache2::Const::OK;
}

1;

__END__
