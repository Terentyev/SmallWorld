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

__END__

1;
