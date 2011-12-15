package Tests::Config;


use strict;
use warnings;
use utf8;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
    SERVER_ADDRESS
);

use constant SERVER_ADDRESS => "server.smallworld";
#use constant SERVER_ADDRESS => "192.168.1.51/small_worlds";

1;

__END__
