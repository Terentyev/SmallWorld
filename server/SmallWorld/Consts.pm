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
  R_CANNOT_CONQUER
  R_NOT_IN_GAME
  R_TOO_MANY_PLAYERS
  R_USERNAME_TAKEN

  PATTERN

  USERS
  PLAYERS
  GAMES
  MAPS

  AMAZONS_CONQ_TOKENS_NUM
  AMAZONS_TOKENS_NUM
  DWARVES_TOKENS_NUM
  ELVES_DEF_TOKENS_NUM
  ELVES_TOKENS_NUM
  GIANTS_CONQ_TOKENS_NUM
  GIANTS_TOKENS_NUM
  HALFLINGS_TOKENS_NUM
  HUMANS_TOKENS_NUM
  ORCS_TOKENS_NUM
  RATMEN_TOKENS_NUM
  SKELETONS_TOKENS_NUM
  SORCERERS_TOKENS_NUM
  TRITONS_CONQ_TOKENS_NUM
  TRITONS_TOKENS_NUM
  TROLLS_DEF_TOKENS_NUM
  TROLLS_TOKENS_NUM
  WIZARDS_TOKENS_NUM

  REGION_TYPE_BORDER
  REGION_TYPE_FARMLAND
  REGION_TYPE_MAGIC
  REGION_TYPE_MINE
  REGION_TYPE_MOUNTAIN
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
use constant R_BAD_TURNS_NUM        => "badTurnsNum"          ;
use constant R_BAD_USERNAME         => "badUsername"          ;
use constant R_CANNOT_CONQUER       => "cannotConquer"        ;
use constant R_NOT_IN_GAME          => "notInGame"            ;
use constant R_TOO_MANY_PLAYERS     => "tooManyPlayers"       ;
use constant R_USERNAME_TAKEN       => "usernameTaken"        ;

use constant MAX_GAMEDESCR_LEN => 300;
use constant MAX_GAMENAME_LEN  => 50 ;
use constant MAX_MAPNAME_LEN   => 15 ;
use constant MAX_PASSWORD_LEN  => 18 ;
use constant MAX_PLAYERS_NUM   => 5  ;
use constant MAX_RACENAME_LEN  => 20 ;
use constant MAX_SKILLNAME_LEN => 20 ;
use constant MAX_TURNS_NUM     => 10 ;
use constant MAX_USERNAME_LEN  => 16 ;
use constant MIN_GAMENAME_LEN  => 1  ;
use constant MIN_PASSWORD_LEN  => 6  ;
use constant MIN_PLAYERS_NUM   => 2  ;
use constant MIN_TURNS_NUM     => 5  ;
use constant MIN_USERNAME_LEN  => 3  ;
use constant RACE_NUM          => 14 ;
use constant VISIBLE_RACES     => 6  ;

use constant PATTERN => {
  register => [
    {
      name => "username",
      type => "unicode",
      mandatory => 1,
      min => MIN_USERNAME_LEN,
      max => MAX_USERNAME_LEN,
      errorCode => R_BAD_USERNAME
    },
    {
      name => "password",
      type => "unicode",
      mandatory => 1,
      min => MIN_PASSWORD_LEN,
      max => MAX_PASSWORD_LEN,
      errorCode => R_BAD_PASSWORD
    }
  ],
  login => [
    {
      name => "username",
      type => "unicode",
      mandatory => 1,
      min => MIN_USERNAME_LEN,
      max => MAX_USERNAME_LEN,
      errorCode => R_BAD_LOGIN
    },
    {
      name => "password",
      type => "unicode",
      mandatory => 1,
      min => MIN_PASSWORD_LEN,
      max => MAX_PASSWORD_LEN,
      errorCode => R_BAD_LOGIN
    }
  ],
  logout => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  sendMessage => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {name => "text", type => "unicode", mandatory => 1}
  ],
  getMessages => [
    {
      name => "since",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID # stupid youth!!!
    }
  ],
  createDefaultMaps => [
    {
      name => "sid",
      type => "int",
      mandatory => 0,
      errorCode => R_BAD_SID
    }
  ],
  uploadMap => [
    {
      name => "mapName",
      type => "unicode",
      mandatory => 1,
      max => MAX_MAPNAME_LEN,
      errorCode => R_BAD_MAP_NAME
    },
    {
      name => "playersNum",
      type => "int",
      mandatory => 1,
      min => MIN_PLAYERS_NUM,
      max => MAX_PLAYERS_NUM,
      errorCode => R_BAD_PLAYERS_NUM
    },
    {
      name => "regions",
      type => "list",
      mandatory => 0,
    },
    {
      name => "turnsNum",
      mandatory => 1,
      type => "int",
      min => MIN_TURNS_NUM,
      max => MAX_TURNS_NUM,
      errorCode => R_BAD_TURNS_NUM
    }
  ],
  createGame => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => "gameName",
      type => "unicode",
      mandatory => 1,
      min => MIN_GAMENAME_LEN,
      max => MAX_GAMENAME_LEN,
      errorCode => R_BAD_GAME_NAME
    },
    {
      name => "mapId",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_MAP_ID
    },
    {
      name => "gameDescr",
      type => "unicode",
      mandatory => 0,
      max => MAX_GAMEDESCR_LEN,
      errorCode => R_BAD_GAME_DESC
    }
  ],
  getGameList => [
    {
      name => "sid",
      type => "int",
      mandatory => 0,
      errorCode => R_BAD_SID
    }
  ],
  joinGame => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => "gameId",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_GAME_ID
    }
  ],
  leaveGame => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  setReadinessStatus => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => "isReady",
      type => "int",
      mandatory => 1,
      min => 0,
      max => 1,
      errorCode => R_BAD_READINESS_STATUS
    },
    {name => "visibleRaces", type => "list", mandatory => 0},
    {name => "visibleSpecialPowers", type => "list", mandatory => 0}
  ],
  selectRace => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => "position",
      type => "int",
      mandatory => 1,
      min => 0,
      max => VISIBLE_RACES - 1,
      errorCode => R_BAD_POSITION
    }
  ],
  doSmth => [
    {
      name => "sid",
      type => "int",
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  conquer => [
    {name => "sid", type => "int", mandatory => 1},
    {name => "regionId", type => "int", mandatory => 1},
    {name => "raceId", type => "int", min => 0, max => RACE_NUM, mandatory => 0}
  ],
  decline =>[ {name => "sid", type => "int", mandatory => 1} ],
  finishTurn => [ {name => "sid", type => "int", mandatory => 1} ],
  redeploy => [
    {name => "sid", type => "int", mandatory => 1},
    {name => "raceId", type => "int", mandatory => 0},
    {name => "regions", type => "list", mandatory => 1}
  ],
  defend => [
    {name => "sid", type => "int", mandatory => 1},
    {name => "regions", type => "list", mandatory => 1}
  ],
  enchant => [
    {name => "sid", type => "int", mandatory => 1},
    {name => "regionId", type => "int", mandatory => 1}
  ],
  getVisibleTokenBadges => [
    {name => "gameId", type => "int", mandatory => 1}
  ],
  resetServer => [ {name => "sid", type => "int", mandatory => 0} ],
  throwDice => [
    {name => "sid", type => "int", mandatory => 1},
    {name => "dice", type => "int", mandatory => 0}
  ]
};

use constant USERS             => "users"          ;
use constant PLAYERS           => "players"        ;
use constant GAMES             => "games"          ;
use constant MAPS              => "maps"           ;

# игровые бонусы и штрафы
use constant AMAZONS_CONQ_TOKENS_NUM => 4;
use constant AMAZONS_TOKENS_NUM      => 6;
use constant DWARVES_TOKENS_NUM      => 3;
use constant ELVES_DEF_TOKENS_NUM    => 1;
use constant ELVES_TOKENS_NUM        => 6;
use constant GIANTS_CONQ_TOKENS_NUM  => 1;
use constant GIANTS_TOKENS_NUM       => 6;
use constant HALFLINGS_TOKENS_NUM    => 6;
use constant HUMANS_TOKENS_NUM       => 5;
use constant ORCS_TOKENS_NUM         => 5;
use constant RATMEN_TOKENS_NUM       => 8;
use constant SKELETONS_TOKENS_NUM    => 6;
use constant SORCERERS_TOKENS_NUM    => 5;
use constant TRITONS_CONQ_TOKENS_NUM => 1;
use constant TRITONS_TOKENS_NUM      => 6;
use constant TROLLS_DEF_TOKENS_NUM   => 1;
use constant TROLLS_TOKENS_NUM       => 5;
use constant WIZARDS_TOKENS_NUM      => 5;

# типы регионов
use constant REGION_TYPE_BORDER   => "border"  ;
use constant REGION_TYPE_FARMLAND => "farmland";
use constant REGION_TYPE_MAGIC    => "magic"   ;
use constant REGION_TYPE_MINE     => "mine"    ;
use constant REGION_TYPE_MOUNTAIN => "mountain";

__END__

1;
