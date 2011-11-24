package Proxy::Server;


use strict;
use warnings;
use utf8;

use Apache2::Const -compile => qw( OK REDIRECT );
use APR::Request::Param;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Message;
use LWP::UserAgent;
use URI::Escape;

sub new {
	my $class = shift;
	my $self = { ua => LWP::UserAgent->new(), request => undef };

	bless $self, $class;

	return $self;
}

sub process {
	my ($self, $r) = @_;
  my $result = Apache2::Const::OK;

  if ( $r->uri() eq '/upload_map' ) {
    $result = $self->proxyUpload($r);
  }
  else {
    $result = $self->proxyCommand($r);
  }

  print $self->{ua}->request($self->{request})->content if defined $self->{request};

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

  $self->{request} = HTTP::Request->new(POST => $address);
  $self->{request}->add_content_utf8($request);
#  $self->{request}->content_type('application/x-www-form-urlencoded');
#  $self->{request}->content("request=" . uri_escape($request)); # вот это надо раскоментировать, чтобы работало у Паши
  return Apache2::Const::OK;
}

sub proxyUpload {
  my ($self, $r) = @_;
  my $body = $r->upload('filename');

  if ( !defined $body || !defined $r->param('mapId') || !defined $r->param('address') ) {
    return $self->redirect($r);
  }

  my $filen = $body->upload_fh();

  $self->{request} = HTTP::Request->new(POST => $r->param('address'));
  $self->{request}->header('Content-Type' => 'multipart/form-data;');
  my $f = HTTP::Message->new(['Content-Disposition' => 'form-data; name="mapId"', 'Content-Type' => 'text/plain; charset=utf-8']);
  $f->add_content_utf8($r->param('mapId'));
  $self->{request}->add_part($f);
  $f = HTTP::Message->new([
      'Content-Disposition' => 'form-data; name="filename"; filename="file' . $body->upload_filename() . '"',
      'Content-Length' => -s $filen]);
  $f->add_content($_) while <$filen>;
  $self->{request}->add_part($f);
  return Apache2::Const::OK;
}

1;

__END__
