package SmallWorld::Consts;


use strict;
use warnings;
use utf8;


require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw(
  R_ALL_OK
  R_ALREADY_IN_GAME
  R_BAD_ACTION
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

  CMD_ERRORS
  PATTERN

  DB_GENERATORS_NAMES
  DB_TABLES_NAMES

  DEFAULT_MAPS
);

use constant R_ALL_OK               => "ok"                   ;
use constant R_ALREADY_IN_GAME      => "alreadyInGame"        ;
use constant R_BAD_ACTION           => "badAction"            ;
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

use constant CMD_ERRORS => {
  register           => [R_BAD_USERNAME, R_BAD_PASSWORD, R_USERNAME_TAKEN],
  login              => [R_BAD_LOGIN],
  logout             => [R_BAD_SID],
  sendMessage        => [R_BAD_SID],
  getMessages        => [],
  createDefaultMaps  => [],
  uploadMap          => [R_BAD_MAP_NAME],
  createGame         => [R_BAD_SID, R_BAD_GAME_NAME, R_BAD_MAP_ID],
  joinGame           => [R_BAD_SID, R_BAD_GAME_ID, R_BAD_GAME_STATE, R_ALREADY_IN_GAME, R_TOO_MANY_PLAYERS],
  leaveGame          => [R_BAD_SID, R_NOT_IN_GAME],
  setReadinessStatus => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_GAME_STATE],
  selectRace         => [R_BAD_SID, R_BAD_POSITION, R_BAD_MONEY_AMOUNT, R_BAD_STAGE],
  doSmth             => [R_BAD_SID],
  resetServer        => []
};

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
  getGameList => [ {name => "sid", type => "int", mandatory => 0} ],
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

use constant DB_GENERATORS_NAMES => ["GEN_MAP_ID", "GEN_GAME_ID", "GEN_MESSAGE_ID", "GEN_SID", "GEN_PLAYER_ID"];
use constant DB_TABLES_NAMES     => ["PLAYERS", "MAPS", "GAMES", "MESSAGES"]                                   ;

use constant DEFAULT_MAPS => [
  {"mapName" => "defaultMap1", "playersNum" => 2, "turnsNum" => 5},
  {"mapName" => "defaultMap2", "playersNum" => 3, "turnsNum" => 5},
  {"mapName" => "defaultMap3", "playersNum" => 4, "turnsNum" => 5},
  {"mapName" => "defaultMap4", "playersNum" => 5, "turnsNum" => 5},
  {"mapName" => "defaultMap5", "playersNum" => 2, "turnsNum" => 5, "regions" => [
    { "population" => 1, "landDescription" => ["mountain"], "adjacent" => [3, 4] },
    { "population" => 1, "landDescription" => ["sea"], "adjacent" => [1, 4] },
    { "population" => 1, "landDescription" => ["border", "mountain"], "adjacent" => [1]},
    { "population" => 1, "landDescription" => ["coast"], "adjacent" => [1, 2] }
  ]},
  {"mapName" => "defaultMap6", "playersNum" => 2, "turnsNum" => 7, "regions" => [
     { "landDescription" => ["sea", "border"], "adjacent" => [1, 16, 17] },                                            # 1
     { "landDescription" => ["mine", "border", "coast", "forest"], "adjacent" => [0, 17, 18, 2] },                     # 2
     { "landDescription" => ["border", "mountain"], "adjacent" => [1, 18, 20, 3] },                                    # 3
     { "landDescription" => ["farmland", "border"], "adjacent" => [2, 20, 21, 4] },                                    # 4
     { "landDescription" => ["cavern", "border", "swamp"], "adjacent" => [3, 21, 22, 5] },                             # 5
     { "population" => 1, "landDescription" => ["forest", "border"], "adjacent" => [4, 22, 6] },                       # 6
     { "landDescription" => ["mine", "border", "swamp"], "adjacent" => [5, 22, 7, 23, 25] },                           # 7
     { "landDescription" => ["border", "mountain", "coast"], "adjacent" => [6, 25, 9, 8, 23] },                        # 8
     { "landDescription" => ["border", "sea"], "adjacent" => [7, 9, 10] },                                             # 9
     { "population" => 1, "landDescription" => ["cavern", "coast"], "adjacent" => [8, 7, 10, 25] },                    #10
     { "population" => 1, "landDescription" => ["mine", "coast", "forest", "border"], "adjacent" => [9, 25, 26, 11] }, #11
     { "landDescription" => ["forest", "border"], "adjacent" => [10, 26, 29, 12] },                                    #12
     { "landDescription" => ["mountain", "border"], "adjacent" => [11, 29, 27, 13] },                                  #13
     { "landDescription" => ["mountain", "border"], "adjacent" => [12, 27, 15, 14] },                                  #14
     { "landDescription" => ["hill", "border"], "adjacent" => [13, 15] },                                              #15
     { "landDescription" => ["farmland", "magic", "border"], "adjacent" => [14, 19, 27, 16] },                         #16
     { "landDescription" => ["border", "mountain", "cavern", "mine", "coast"], "adjacent" => [15, 19, 0, 17] },        #17
     { "population" => 1, "landDescription" => ["farmland", "magic", "coast"], "adjacent" => [16, 19, 0, 18] },        #18
     { "landDescription" => ["swamp"], "adjacent" => [17, 2, 20, 1, 19] },                                             #19
     { "population" => 1, "landDescription" => ["swamp"], "adjacent" => [18, 27, 28, 20] },                            #20
     { "population" => 1, "landDescription" => ["hill", "magic"], "adjacent" => [19, 28, 2, 3, 21] },                  #21
     { "landDescription" => ["mountain", "mine"], "adjacent" => [20, 24, 28, 3, 4, 22] },                              #22
     { "population" => 1, "landDescription" => ["farmland"], "adjacent" => [21, 24, 5, 4, 23] },                       #23
     { "landDescription" => ["hill", "magic"], "adjacent" => [22, 25, 6, 24, 7] },                                     #24
     { "landDescription" => ["mountain", "cavern"], "adjacent" => [23, 21, 22, 28] },                                  #25
     { "population" => 1, "landDescription" => ["farmland"], "adjacent" => [24, 23, 6, 7, 9, 10, 26] },                #26
     { "population" => 1, "landDescription" => ["swamp", "magic"], "adjacent" => [25, 10, 11, 29, 28] },               #27
     { "population" => 1, "landDescription" => ["forest", "cavern"], "adjacent" => [28, 29, 12, 13, 15, 19] },         #28
     { "landDescription" => ["sea"], "adjacent" => [27, 19, 20, 21, 24, 26, 29] },                                     #29
     { "landDescription" => ["hill"], "adjacent" => [28, 27, 12, 11, 26] }                                             #30
   ] },
   { "mapName" => "defaultMap7", "playersNum" => 2, "turnsNum" => 5, "regions" => [
     { "landDescription" => ["border", "mountain", "mine", "farmland","magic"], "adjacent" => [2] },
     { "landDescription" => ["mountain"], "adjacent" => [1, 3] },
     { "population" => 1, "landDescription" => ["mountain", "mine"], "adjacent" => [2, 4] },
     { "population" => 1, "landDescription" => ["mountain"], "adjacent" => [3, 5] },
     { "landDescription" => ["mountain", "mine"], "adjacent" => [4] }
   ] }
];


__END__

1;
