package SmallWorld::Config;

use strict;
use warnings;
use utf8;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
    DB_NAME
    DB_LOGIN
    DB_PASSWORD
    DB_MAX_BLOB_SIZE
    TEST_MODE
    TEST_RANDSEED

    MAP_IMGS_DIR
    MAP_IMG_PREFIX
);


use constant DB_NAME          => $ENV{DB_PATH};
use constant DB_LOGIN         => 'sysdba';
use constant DB_PASSWORD      => 'masterkey';
use constant DB_MAX_BLOB_SIZE => 1048576;
use constant TEST_MODE        => 1;
use constant TEST_RANDSEED    => 12345;

use constant MAP_IMGS_DIR     => $ENV{DOCUMENT_ROOT} . '/public/imgs/';
use constant MAP_IMG_PREFIX   => 'map_';

1;
