package SmallWorld::Uploader;


use strict;
use warnings;
use utf8;

use APR::Request::Param;

use SmallWorld::Config;

sub new {
  my $class = shift;
  my $self = { };

  bless $self, $class;

  return $self;
}

sub map_upload {
  my ($self, $r) = @_;
  my $body = $r->upload('filename');

  if ( !defined $body || !defined $r->param('mapId') ) {
    print "Bad body or bad mapId";
    return 0;
  }

  my $ext = ($body->upload_filename() =~ m/.*(\..+)$/)[0];

  if ( !defined $ext || $ext !~ m/^\.(png|jpeg|jpg)$/ ) {
    print "Bad file extension";
    return 0;
  }

  my $filen = $body->upload_fh();

  if ( $filen ) {
    open FL, '>' . MAP_IMGS_DIR . MAP_IMG_PREFIX . $r->param('mapId') . $ext;
    binmode FL;
    binmode $filen;
    while( <$filen> ){
      print FL $_;
    }
    close FL;
    print "OK";
  }
}

1;

__END__
