package SW::Util;


use strict;
use warnings;
use utf8;

use base ('Exporter');
our @EXPORT_OK = qw(
    swLog
);

sub swLog {
  return if !$ENV{DEBUG};
  my $file = shift;
  use Data::Dumper;
  open FL, ">> $file";
  print FL Dumper(@_);
  close FL;
}

1;

__END__
