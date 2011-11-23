package SmallWorld::Server;


use strict;
use warnings;
use utf8;

use APR::Brigade ();
use APR::Bucket ();
use Apache2::Connection ();
use Apache2::Filter ();

use Apache2::Const -compile => qw(MODE_READBYTES);
use APR::Const    -compile => qw(SUCCESS BLOCK_READ);

use SmallWorld::Processor;
use SmallWorld::Uploader;

use constant IOBUFSIZE => 8192;


sub new {
	my $class = shift;
	my $self = { processor => SmallWorld::Processor->new(), uploader => SmallWorld::Uploader->new() };

	bless $self, $class;

	return $self;
}

sub process {
  my ($self, $r) = @_;
  if ( $r->uri() eq '/upload_map' ) {
    $self->{uploader}->map_upload($r);
  }
  else {
    $self->{processor}->process(content($r));
#    $self->{processor}->process($r->param('request'));
  }
}

# код по выдергиванию json-запроса взят из примера по адресу:
# (понятия не имею, почему такая элементарная вещь написана так сложно...)
# http://perl.apache.org/docs/2.0/user/handlers/http.html#toc_PerlHeaderParserHandler
sub content {
  my $r = shift;

  my $bb = APR::Brigade->new($r->pool, $r->connection->bucket_alloc);

  my $data = '';
  my $seen_eos = 0;
  do {
    $r->input_filters->get_brigade($bb, 
      Apache2::Const::MODE_READBYTES,
      APR::Const::BLOCK_READ, IOBUFSIZE);

    for (my $b = $bb->first; $b; $b = $bb->next($b)) {
      if ($b->is_eos) {
        $seen_eos++;
        last;
      }

      if ($b->read(my $buf)) {
        $data .= $buf;
      }

      $b->remove; # optimization to reuse memory
    }
  } while (!$seen_eos);

  $bb->destroy;
  
  return $data;
}

1;

__END__
