package Proxy::Config;


use strict;
use warnings;
use utf8;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
    LOG_FILE
);


use constant LOG_FILE => '/var/log/apache2/proxy.log';
