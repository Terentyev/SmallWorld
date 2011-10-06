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
  R_BAD_GAME_DESC
  R_BAD_GAME_ID
  R_BAD_GAME_NAME
  R_BAD_GAME_STATE
  R_BAD_JSON
  R_BAD_LOGIN
  R_BAD_MAP_ID
  R_BAD_MAP_NAME
  R_BAD_MONEY_AMOUNT
  R_BAD_NUM_OF_PLAYERS
  R_BAD_PASSWORD
  R_BAD_PLAYERS_NUM
  R_BAD_POSITION
  R_BAD_READINESS_STATUS
  R_BAD_SID
  R_BAD_STAGE
  R_BAD_USERNAME
  R_NOT_IN_GAME
  R_TOO_MANY_PLAYERS
  R_USERNAME_TAKEN

  USERS
  PLAYERS
  GAMES
  MAPS
);

use constant R_ALL_OK               => "ok"                   ;
use constant R_ALREADY_EXISTS       => "already exists"       ;
use constant R_ALREADY_IN_GAME      => "alreadyInGame"        ;
use constant R_ALREADY_TAKEN        => "already taken"        ;
use constant R_BAD_GAME_DESC        => "badGameDescription"   ;
use constant R_BAD_GAME_ID          => "badGameId"            ;
use constant R_BAD_GAME_NAME        => "badGameName"          ;
use constant R_BAD_GAME_STATE       => "badGameState"         ;
use constant R_BAD_JSON             => "badJson"              ;
use constant R_BAD_LOGIN            => "badUsernameOrPassword";
use constant R_BAD_MAP_ID           => "badMapId"             ;
use constant R_BAD_MAP_NAME         => "badMapName"           ;
use constant R_BAD_MONEY_AMOUNT     => "badMoneyAmount"       ;
use constant R_BAD_NUM_OF_PLAYERS   => "badNumberOfPlayers"   ;
use constant R_BAD_PASSWORD         => "badPassword"          ;
use constant R_BAD_PLAYERS_NUM      => "badPlayersNum"        ;
use constant R_BAD_POSITION         => "badPosition"          ;
use constant R_BAD_READINESS_STATUS => "badReadinessStatus"   ;
use constant R_BAD_SID              => "badSid"               ;
use constant R_BAD_STAGE            => "badStage"             ;
use constant R_BAD_USERNAME         => "badUsername"          ;
use constant R_NOT_IN_GAME          => "notInGame"            ;
use constant R_TOO_MANY_PLAYERS     => "tooManyPlayers"       ;
use constant R_USERNAME_TAKEN       => "usernameTaken"        ;

use constant MIN_USERNAME_LEN  => 3  ;
use constant MIN_PASSWORD_LEN  => 6  ;
use constant MAX_USERNAME_LEN  => 16 ;
use constant MAX_PASSWORD_LEN  => 18 ;
use constant MAX_MAPNAME_LEN   => 15 ;
use constant MIN_PLAYERS_NUM   => 2  ;
use constant MAX_PLAYERS_NUM   => 5  ;
use constant MIN_GAMENAME_LEN  => 1  ;
use constant MAX_GAMENAME_LEN  => 50 ;
use constant MAX_RACENAME_LEN  => 20 ;
use constant MAX_SKILLNAME_LEN => 20 ;
use constant MAX_GAMEDESCR_LEN => 300;

use constant USERS             => "users"          ;
use constant PLAYERS           => "players"        ;
use constant GAMES             => "games"          ;
use constant MAPS              => "maps"           ;


__END__

1;
