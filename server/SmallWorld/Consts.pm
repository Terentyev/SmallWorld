package SmallWorld::Consts;


use strict;
use warnings;
use utf8;


require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
  R_ALL_OK
  R_ALREADY_EXISTS
  R_ALREADY_IN_GAME
  R_ALREADY_TAKEN
  R_BAD_RULES
  R_DEFINE_ERROR
  R_INVALID_GAME
  R_LINK_ERROR
  R_MALFORMED
  R_NOT_IN_GAME
  R_UNKNOWN_CMD
  R_UNKNOWN_GAME 
  R_UNKNOWN_MAP
  R_UNKNOWN_PLAYER

  USERS
  PLAYERS
  GAMES
  MAPS
);

use constant R_ALL_OK          => "ok"             ;
use constant R_ALREADY_EXISTS  => "already exists" ;
use constant R_ALREADY_IN_GAME => "already in game";
use constant R_ALREADY_TAKEN   => "already taken"  ;
use constant R_BAD_RULES       => "bad rules"      ;
use constant R_DEFINE_ERROR    => "define error"   ;
use constant R_INVALID_GAME    => "invalid game"   ;
use constant R_LINK_ERROR      => "link error"     ;
use constant R_MALFORMED       => "malformed"      ;
use constant R_NOT_IN_GAME     => "not in game"    ;
use constant R_UNKNOWN_CMD     => "unknown command";
use constant R_UNKNOWN_GAME    => "unknown game"   ;
use constant R_UNKNOWN_MAP     => "unknown map"    ;
use constant R_UNKNOWN_PLAYER  => "unknown player" ;


use constant USERS             => "users"          ;
use constant PLAYERS           => "players"        ;
use constant GAMES             => "games"          ;
use constant MAPS              => "maps"           ;


__END__

1;
