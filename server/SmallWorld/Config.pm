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

    MAP_IMG_PREFIX
    MAP_IMG_URL_PREFIX
    MAP_IMGS_DIR

    LOG_FILE
);


use constant DB_NAME          => $ENV{DB_PATH};
use constant DB_LOGIN         => 'sysdba';
use constant DB_PASSWORD      => 'masterkey';
use constant DB_MAX_BLOB_SIZE => 1048576;
use constant TEST_MODE        => 1;
use constant TEST_RANDSEED    => 12345;

use constant MAP_IMG_PREFIX     => 'map_';
use constant MAP_IMG_URL_PREFIX => '/public/imgs/';
use constant MAP_IMGS_DIR       => $ENV{DOCUMENT_ROOT} . MAP_IMG_URL_PREFIX;

use constant LOG_FILE           => '/var/log/apache2/server.log';

1;

__END__
