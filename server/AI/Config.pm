package AI::Config;


use strict;
use warnings;
use utf8;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
    DEFAULT_SERVER_ADDRESS
    DEFAULT_TIMEOUT
);


use constant DEFAULT_SERVER_ADDRESS => 'server.smallworld';
use constant DEFAULT_TIMEOUT        => 1;

1;

__END__
