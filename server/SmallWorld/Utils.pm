package SmallWorld::Utils;


use strict;
use warnings;
use utf8;

use JSON;

require Exporter;
sub BEGIN {
  our @ISA    = qw( Exporter );
  our @export_list;

  my $filename = __FILE__;
  open ME, "<$filename" or die "Can't open $filename for input: $!";
  my @lines = <ME>;
  foreach ( @lines ) {
    if ( m/^sub\s+([a-z][A-Za-z_]+)\s+/x ) {
      push @export_list, $1;
    }
  }

  our @EXPORT = @export_list;
}

sub bool {
  return $_[1] ? JSON::true : JSON::false;
}
