package AI::Config;


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

    DEFAULT_REQ_LOG_SIZE
    DEFAULT_SERVER_ADDRESS
    DEFAULT_TIMEOUT

    LOG_FILE
);


use constant DB_NAME                => '/var/www/SmallWorld/server/db/AI.FDB';
use constant DB_LOGIN               => 'sysdba';
use constant DB_PASSWORD            => 'masterkey';
use constant DB_MAX_BLOB_SIZE       => 10485760;
use constant DEFAULT_REQ_LOG_SIZE   => 20;
use constant DEFAULT_SERVER_ADDRESS => 'server.smallworld';
use constant DEFAULT_TIMEOUT        => 2;

use constant LOG_FILE               => 'ai.log';

1;

__END__
