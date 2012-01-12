package SW::Util;


use strict;
use warnings;
use utf8;

use base ('Exporter');
our @EXPORT_OK = qw(
    swLog
    timeStart
    timeEnd
);

use Benchmark;

our @stackTime = ();

sub swLog {
  return if !$ENV{DEBUG};
  my $file = shift;
  use Data::Dumper;
  open(FL, '>>', $file);
  print FL Dumper(@_);
  close FL;
}

sub timeStart {
  push @stackTime, Benchmark->new;
}

sub timeEnd {
  my $t = Benchmark->new;
  my $f = shift;
  swLog($f, ($_[0] // '') . timestr(timediff($t, pop(@stackTime))));
}

1;

__END__
