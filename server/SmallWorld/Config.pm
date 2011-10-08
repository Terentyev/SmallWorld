package SmallWorld::Config;

use strict;
use warnings;
use utf8;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( DB_NAME DB_LOGIN DB_PASSWORD DB_MAX_BLOB_SIZE );


use constant DB_NAME          => $ENV{DB_PATH};
use constant DB_LOGIN         => "sysdba";
use constant DB_PASSWORD      => "masterkey";
use constant DB_MAX_BLOB_SIZE => 1048576;

1;
