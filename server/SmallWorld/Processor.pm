package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON;

use SmallWorld::Consts;


sub new {
  my $class = shift;
  my $self = { json => undef, db => undef };
  my ($r) = @_;
  if ( !$r ) {
    $r = "{}";
  }

  my $json = JSON->new;
  $json = $json->allow_nonref([1]);
  $self->{json} = eval { return $json->decode($r) or {}; };
  $self->{db} = SmallWorld::DB->new;

  bless $self, $class;
  return $self;
}

sub process {
  my ($self) = @_;
  $self->debug();
  my $js = $self->{json};
  my $cmd = $js->{command};
  my $result = { result => R_ALL_OK };
  my $json = JSON->new;
  my $str = "";
  if ( $cmd && exists &{"_$cmd"} ) {
    my $func = \&{"cmd_$cmd"};
    if ( !$func )
    {
      $result->{result} = R_UNKNOWN_CMD;
    }
    else
    {
      &$func($self, $result);
    }
  }
  else {
    $result->{result} = R_MALFORMED;
  }
  $str = $json->encode($result) or die "Can not encode JSON-object\n";
  print $str;
}

sub debug {
  my ($self) = @_;
  return if $ENV{DEBUG};
  use Data::Dumper; print Dumper($self);
}

1;

__END__
