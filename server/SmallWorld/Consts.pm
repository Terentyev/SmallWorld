package SmallWorld::Consts;


use strict;
use warnings;
use utf8;


require Exporter;
sub BEGIN {
  our @ISA    = qw( Exporter );
  our @export_list;

  my $filename = __FILE__;
  open ME, "<$filename" or die "Can't open $filename for input: $!";
  my @lines = <ME>;
  foreach ( @lines ) {
    if ( m/^\s*use\s+constant\s+([A-Z_]+)\s+/x ) {
      push @export_list, $1;
    }
  }

  our @EXPORT = @export_list;
}

use constant R_ALL_OK                       => 'ok'                                 ;
use constant R_ALREADY_IN_GAME              => 'alreadyInGame'                      ;
use constant R_BAD_ACTION                   => 'badAction'                          ;
use constant R_BAD_ATTACKED_RACE            => 'badAttackedRace'                    ;
use constant R_BAD_BODY_OR_MAPID            => 'badBodyOrMapId'                     ;
use constant R_BAD_COORDINATES              => 'badCoordinates'                     ;
use constant R_BAD_ENCAMPMENTS_NUM          => 'badEncampmentsNum'                  ;
use constant R_BAD_FILE_EXTENSION           => 'badFileExtension'                   ;
use constant R_BAD_FRIEND                   => 'badFriend'                          ;
use constant R_BAD_FRIEND_ID                => 'badFriendId'                        ;
use constant R_BAD_GAME_DESC                => 'badGameDescription'                 ;
use constant R_BAD_GAME_ID                  => 'badGameId'                          ;
use constant R_BAD_GAME_NAME                => 'badGameName'                        ;
use constant R_BAD_GAME_STATE               => 'badGameState'                       ;
use constant R_BAD_JSON                     => 'badJson'                            ;
use constant R_BAD_LOGIN                    => 'badUsernameOrPassword'              ;
use constant R_BAD_MAP_ID                   => 'badMapId'                           ;
use constant R_BAD_MAP_NAME                 => 'badMapName'                         ;
use constant R_BAD_MESSAGE_TEXT             => 'badMessageText'                     ;
use constant R_BAD_MONEY_AMOUNT             => 'badMoneyAmount'                     ;
use constant R_BAD_PASSWORD                 => 'badPassword'                        ;
use constant R_BAD_PLAYERS_NUM              => 'badPlayersNum'                      ;
use constant R_BAD_POSITION                 => 'badPosition'                        ;
use constant R_BAD_POWER_COORDINATES        => 'badPowerCoordinates'                ;
use constant R_BAD_RACE_COORDINATES         => 'badRaceCoordinates'                 ;
use constant R_BAD_READINESS_STATUS         => 'badReadinessStatus'                 ;
use constant R_BAD_REGION                   => 'badRegion'                          ;
use constant R_BAD_REGION_ID                => 'badRegionId'                        ;
use constant R_BAD_REGIONS                  => 'badRegions'                         ;
use constant R_BAD_SET_HERO_CMD             => 'badSetHeroCommand'                  ;
use constant R_BAD_SID                      => 'badUserSid'                         ;
use constant R_BAD_SINCE                    => 'badSince'                           ;
use constant R_BAD_STAGE                    => 'badStage'                           ;
use constant R_BAD_TOKENS_NUM               => 'badTokensNum'                       ;
use constant R_BAD_TURNS_NUM                => 'badTurnsNum'                        ;
use constant R_BAD_USERNAME                 => 'badUsername'                        ;
use constant R_CANNOT_ENCHANT               => 'cannotEnchantDeclinedRace'          ;
use constant R_GAME_NAME_TAKEN              => 'gameNameTaken'                      ;
use constant R_MAP_NAME_TAKEN               => 'mapNameTaken'                       ;
use constant R_NO_MORE_TOKENS_IN_STORAGE    => 'noMoreTokensInStorageTray'          ;
use constant R_NO_TOKENS_FOR_REDEPLOYMENT   => 'noTokensForRedeployment'            ;
use constant R_NOT_ENOUGH_ENCAMPS           => 'notEnoughEncampmentsForRedeployment';
use constant R_NOT_ENOUGH_TOKENS            => 'notEnoughTokens'                    ;
use constant R_NOT_ENOUGH_TOKENS_FOR_R      => 'notEnoughTokensForRedeployment'     ;
use constant R_NOT_IN_GAME                  => 'notInGame'                          ;
use constant R_NOTHING_TO_ENCHANT           => 'nothingToEnchant'                   ;
use constant R_REGION_IS_IMMUNE             => 'regionIsImmune'                     ;
use constant R_THERE_ARE_TOKENS_IN_THE_HAND => 'thereAreTokensInTheHand'            ;
use constant R_TOO_MANY_FORTS               => 'tooManyFortifieds'                  ;
use constant R_TOO_MANY_FORTS_IN_REGION     => 'tooManyFortifiedsInRegion'          ;
use constant R_TOO_MANY_PLAYERS             => 'tooManyPlayers'                     ;
use constant R_USER_HAS_NOT_REGIONS         => 'userHasNotRegions'                  ;
use constant R_USERNAME_TAKEN               => 'usernameTaken'                      ;

use constant MAX_GAMEDESCR_LEN  => 300;
use constant MAX_GAMENAME_LEN   => 50 ;
use constant MAX_MAPNAME_LEN    => 15 ;
use constant MAX_MSG_LEN        => 300;
use constant MAX_PASSWORD_LEN   => 18 ;
use constant MAX_PLAYERS_NUM    => 5  ;
use constant MAX_RACENAME_LEN   => 20 ;
use constant MAX_SKILLNAME_LEN  => 20 ;
use constant MAX_TURNS_NUM      => 10 ;
use constant MAX_USERNAME_LEN   => 16 ;
use constant MIN_GAMENAME_LEN   => 1  ;
use constant MIN_PASSWORD_LEN   => 6  ;
use constant MIN_PLAYERS_NUM    => 2  ;
use constant MIN_TURNS_NUM      => 5  ;
use constant MIN_USERNAME_LEN   => 3  ;
use constant RACE_NUM           => 14 ;
use constant VISIBLE_BADGES_NUM => 6  ;

use constant CMD_ERRORS => {
  conquer            => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_REGION_IS_IMMUNE, R_BAD_REGION, R_BAD_TOKENS_NUM
  ],
  createDefaultMaps  => [],
  createGame         => [R_BAD_SID, R_GAME_NAME_TAKEN, R_BAD_MAP_ID, R_ALREADY_IN_GAME],
  decline            => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE # R_BAD_GAME_STATE
  ],
  defend             => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_NOT_ENOUGH_TOKENS, R_THERE_ARE_TOKENS_IN_THE_HAND
  ],
  dragonAttack       => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_REGION_IS_IMMUNE
  ],
  enchant            => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_BAD_ATTACKED_RACE, R_NOTHING_TO_ENCHANT, R_CANNOT_ENCHANT,
    R_NO_MORE_TOKENS_IN_STORAGE, R_REGION_IS_IMMUNE
  ],
  finishTurn         => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE], # R_BAD_GAME_STATE
  getGameList        => [R_BAD_SID],
  getGameState       => [R_BAD_GAME_ID],
  getMapList         => [R_BAD_SID],
  getMessages        => [],
  joinGame           => [R_BAD_SID, R_BAD_GAME_ID, R_BAD_GAME_STATE, R_ALREADY_IN_GAME, R_TOO_MANY_PLAYERS],
  leaveGame          => [R_BAD_SID, R_NOT_IN_GAME],
  login              => [R_BAD_LOGIN],
  logout             => [R_BAD_SID],
  redeploy           => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_USER_HAS_NOT_REGIONS, R_BAD_TOKENS_NUM, R_NOT_ENOUGH_TOKENS_FOR_R,
    R_TOO_MANY_FORTS_IN_REGION, R_TOO_MANY_FORTS, R_NOT_ENOUGH_ENCAMPS,
    R_BAD_SET_HERO_CMD, R_NO_TOKENS_FOR_REDEPLOYMENT, R_BAD_ENCAMPMENTS_NUM
  ],
  register           => [R_BAD_USERNAME, R_BAD_PASSWORD, R_USERNAME_TAKEN],
  resetServer        => [],
  selectFriend       => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_FRIEND_ID, R_BAD_FRIEND], # R_BAD_GAME_STATE
  selectRace         => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_MONEY_AMOUNT, R_BAD_STAGE], # R_BAD_POSITION R_BAD_GAME_STATE
  sendMessage        => [R_BAD_SID],
  setReadinessStatus => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_GAME_STATE],
  throwDice          => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE], # R_BAD_GAME_STATE
  uploadMap          => [R_MAP_NAME_TAKEN, R_BAD_REGIONS],
};

use constant PATTERN => {
  register => [
    {
      name => 'username',
      type => 'unicode',
      mandatory => 1,
      min => MIN_USERNAME_LEN,
      max => MAX_USERNAME_LEN,
      errorCode => R_BAD_USERNAME
    },
    {
      name => 'password',
      type => 'unicode',
      mandatory => 1,
      min => MIN_PASSWORD_LEN,
      max => MAX_PASSWORD_LEN,
      errorCode => R_BAD_PASSWORD
    }
  ],
  login => [
    {
      name => 'username',
      type => 'unicode',
      mandatory => 1,
      min => MIN_USERNAME_LEN,
      max => MAX_USERNAME_LEN,
      errorCode => R_BAD_LOGIN
    },
    {
      name => 'password',
      type => 'unicode',
      mandatory => 1,
      min => MIN_PASSWORD_LEN,
      max => MAX_PASSWORD_LEN,
      errorCode => R_BAD_LOGIN
    }
  ],
  logout => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  sendMessage => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'text',
      type => 'unicode',
      max => MAX_MSG_LEN,
      mandatory => 1,
      errorCode => R_BAD_MESSAGE_TEXT
    }
  ],
  getMessages => [
    {
      name => 'since',
      type => 'int',
      mandatory => 1,
      min => 0,
      errorCode => R_BAD_SINCE
    }
  ],
  createDefaultMaps => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 0,
      errorCode => R_BAD_SID
    }
  ],
  uploadMap => [
    {
      name => 'mapName',
      type => 'unicode',
      mandatory => 1,
      min => 1,
      max => MAX_MAPNAME_LEN,
      errorCode => R_BAD_MAP_NAME
    },
    {
      name => 'playersNum',
      type => 'int',
      mandatory => 1,
      min => MIN_PLAYERS_NUM,
      max => MAX_PLAYERS_NUM,
      errorCode => R_BAD_PLAYERS_NUM
    },
    {
      name => 'regions',
      type => 'list',
      mandatory => 1,
      errorCode => R_BAD_REGIONS
    },
    {
      name => 'turnsNum',
      mandatory => 1,
      type => 'int',
      min => MIN_TURNS_NUM,
      max => MAX_TURNS_NUM,
      errorCode => R_BAD_TURNS_NUM
    },
  ],
  createGame => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'gameName',
      type => 'unicode',
      mandatory => 1,
      min => MIN_GAMENAME_LEN,
      max => MAX_GAMENAME_LEN,
      errorCode => R_BAD_GAME_NAME
    },
    {
      name => 'mapId',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_MAP_ID
    },
    {
      name => 'gameDescr',
      type => 'unicode',
      mandatory => 0,
      max => MAX_GAMEDESCR_LEN,
      errorCode => R_BAD_GAME_DESC
    }
  ],
  getGameList => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 0,
      errorCode => R_BAD_SID
    }
  ],
  getMapList => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 0,
      errorCode => R_BAD_SID
    }
  ],
  joinGame => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'gameId',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_GAME_ID
    }
  ],
  leaveGame => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  setReadinessStatus => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'isReady',
      type => 'int',
      mandatory => 1,
      min => 0,
      max => 1,
      errorCode => R_BAD_READINESS_STATUS
    },
    {name => 'visibleRaces', type => 'list', mandatory => 0},
    {name => 'visibleSpecialPowers', type => 'list', mandatory => 0}
  ],
  selectRace => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'position',
      type => 'int',
      mandatory => 1,
      min => 0,
      max => VISIBLE_BADGES_NUM - 1,
      errorCode => R_BAD_POSITION
    }
  ],
  conquer => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'regionId',
      type => 'int',
      min => 1, # нумерация регионов начинается с 1 (stupid youth!!!)
      mandatory => 1,
      errorCode => R_BAD_REGION_ID
    }
  ],
  decline =>[
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  finishTurn => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ],
  redeploy => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'regions',
      type => 'list',
      mandatory => 1,
      errorCode => R_BAD_REGION
    },
    {name => 'encampments', type => 'list', mandatory => 0},
    {name => 'fortified', type => 'hash', mandatory => 0},
    {name => 'heroes', type => 'list', mandatory => 0}
  ],
  defend => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'regions',
      type => 'list',
      mandatory => 1,
      errorCode => R_BAD_REGION
    }
  ],
  enchant => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
     name => 'regionId',
     type => 'int',
     mandatory => 1,
     errorCode => R_BAD_REGION_ID
    }
  ],
  resetServer => [ {name => 'sid', type => 'int', mandatory => 0} ],
  throwDice => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {name => 'dice', type => 'int', mandatory => 0}
  ],
  dragonAttack => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'regionId',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_REGION_ID
    }
  ],
  selectFriend => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    },
    {
      name => 'friendId',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_FRIEND_ID
    }
  ],
  getGameState => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 0,
      errorCode => R_BAD_SID
    },
    {
      name => 'gameId',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_GAME_ID
    }
  ]
};

use constant DB_GENERATORS_NAMES => ['GEN_MAP_ID', 'GEN_GAME_ID', 'GEN_MESSAGE_ID', 'GEN_SID', 'GEN_PLAYER_ID', 'GEN_CONNECTION_ID'];
use constant DB_TABLES_NAMES     => ['PLAYERS', 'MAPS', 'GAMES', 'MESSAGES', 'CONNECTIONS']                                         ;

use constant LENA_DEFAULT_MAP_PICTURE => '';
use constant LENA_DEFAULT_MAPS => [
  {'mapName'=> 'defaultMap1', 'playersNum'=> 2, 'turnsNum'=> 5,
    },
  {'mapName'=> 'defaultMap2', 'playersNum'=> 3, 'turnsNum'=> 5,
    },
  {'mapName'=> 'defaultMap3', 'playersNum'=> 4, 'turnsNum'=> 5,
    },
  {'mapName'=> 'defaultMap4', 'playersNum'=> 5, 'turnsNum'=> 5,
    },
  {
    'mapName'=> 'defaultMap5',
    'playersNum'=> 2,
    'turnsNum'=> 5,
    'regions' =>
    [
      {
        'population' => 1,
        'landDescription' => ['mountain'],
        'adjacent' => [3, 4]
      },
      {
        'population' => 1,
        'landDescription' => ['sea'],
        'adjacent' => [1, 4]
      },
      {
        'population' => 1,
        'landDescription' => ['border', 'mountain'],
        'adjacent' => [1]
      },
      {
        'population' => 1,
        'landDescription' => ['coast'],
        'adjacent' => [1, 2]
      }
    ],
  },
  {
    'mapName'=> 'defaultMap6',
    'playersNum'=> 2,
    'turnsNum'=> 7,
    'regions' =>
    [
      {
        'landDescription' => ['sea', 'border'], #1
        'adjacent' => [2, 17, 18]
      },
      {
        'landDescription' => ['mine', 'border', 'coast', 'forest'], #2
        'adjacent' => [1, 18, 19, 3]
      },
      {
        'landDescription' => ['border', 'mountain'], #3
        'adjacent' => [2, 19, 21, 4]
      },
      {
        'landDescription' => ['farmland', 'border'], #4
        'adjacent' => [3, 21, 22, 5]
      },
      {
        'landDescription' => ['cavern', 'border', 'swamp'], #5
        'adjacent' => [4, 22, 23, 6]
      },
      {
        'population'=> 1,
        'landDescription' => ['forest', 'border'], #6
        'adjacent' => [5, 23, 7]
      },
      {
        'landDescription' => ['mine', 'border', 'swamp'], #7
        'adjacent' => [6, 23, 8, 24, 26]
      },
      {
        'landDescription' => ['border', 'mountain', 'coast'], #8
        'adjacent' => [7, 26, 10, 9, 24]
      },
      {
        'landDescription' => ['border', 'sea'], #9
        'adjacent' => [8, 10, 11]
      },
      {
        'population'=> 1,
        'landDescription' => ['cavern', 'coast'], #10
        'adjacent' => [9, 8, 11, 26]
      },
      {
        'population'=> 1,
        'landDescription' => ['mine', 'coast', 'forest', 'border'], #11
        'adjacent' => [10, 26, 27, 12]
      },
      {
        'landDescription' => ['forest', 'border'], #12
        'adjacent' => [11, 27, 30, 13]
      },
      {
        'landDescription' => ['mountain', 'border'], #13
        'adjacent' => [12, 30, 28, 14]
      },
      {
        'landDescription' => ['mountain', 'border'], #14
        'adjacent' => [13, 28, 16, 15]
      },
      {
        'landDescription' => ['hill', 'border'], #15
        'adjacent' => [14, 16]
      },
      {
        'landDescription' => ['farmland', 'magic', 'border'], #16
        'adjacent' => [15, 20, 28, 17]
      },
      {
        'landDescription' => ['border', 'mountain', 'cavern', 'mine', #17
          'coast'],
        'adjacent' => [16, 20, 1, 18]
      },
      {
        'population'=> 1,
        'landDescription' => ['farmland', 'magic', 'coast'], #18
        'adjacent' => [17, 20, 1, 19]
      },
      {
        'landDescription' => ['swamp'], #19
        'adjacent' => [18, 3, 21, 2, 20]
      },
      {
        'population'=> 1,
        'landDescription' => ['swamp'], #20
        'adjacent' => [19, 28, 29, 21]
      },
      {
        'population'=> 1,
        'landDescription' => ['hill', 'magic'], #21
        'adjacent' => [20, 29, 3, 4, 22]
      },
      {
        'landDescription' => ['mountain', 'mine'], #22
        'adjacent' => [21, 25, 29, 4, 5, 23]
      },
      {
        'population'=> 1,
        'landDescription' => ['farmland'], #23
        'adjacent' => [22, 25, 6, 5, 24]
      },
      {
        'landDescription' => ['hill', 'magic'], #24
        'adjacent' => [23, 26, 7, 25, 8]
      },
      {
        'landDescription' => ['mountain', 'cavern'], #25
        'adjacent' => [24, 22, 23, 29]
      },
      {
        'landDescription' => ['farmland'], #26
        'adjacent' => [25, 24, 7, 8, 10, 11, 27]
      },
      {
        'population'=> 1,
        'landDescription' => ['swamp', 'magic'], #27
        'adjacent' => [26, 11, 12, 30, 29]
      },
      {
        'population'=> 1,
        'landDescription' => ['forest', 'cavern'], #28
        'adjacent' => [29, 30, 13, 14, 16, 20]
      },
      {
        'landDescription' => ['sea'],
        'adjacent' => [28, 20, 21, 22, 25, 27, 30]  #29
      },
      {
        'landDescription' => ['hill'],  #30
        'adjacent' => [29, 28, 13, 12, 27]
      },
    ],
  },  {
    'mapName'=> 'defaultMap7',
    'playersNum'=> 2,
    'turnsNum'=> 5,
    'regions' =>
    [
      {
        'landDescription' => ['border', 'mountain', 'mine', 'farmland','magic'],
        'adjacent' => [2]
      },
      {
        'landDescription' => ['mountain'],
        'adjacent' => [1, 3]
      },
      {
        'population'=> 1,
        'landDescription' => ['mountain', 'mine'],
        'adjacent' => [2, 4]
      },
      {
        'population'=> 1,
        'landDescription' => ['mountain'],
        'adjacent' => [3, 5]
      },
      {
        'landDescription' => ['mountain', 'mine'],
        'adjacent' => [4]
      }
    ]
  }

];


use constant DEFAULT_MAPS => [
  {mapName => 'Are you lucky?', playersNum => 2, turnsNum => 5, regions =>[
    {
      population  => 1, landDescription => ['border', 'coast'], adjacent => [2],
      coordinates => [ [0,0], [300,0], [300,399], [0,399] ],
      raceCoords  => [164,117],
      powerCoords => [172,292]
    },
    {
      population  => 0, landDescription => ['border'], adjacent => [1],
      coordinates => [ [300,0], [300,399], [639,399], [639,0] ],
      raceCoords  => [502,199],
      powerCoords => [493,287]
    },
  ]},
  {mapName => 'Cheburashka', playersNum => 3, turnsNum => 5, regions => [
    {
      population  => 1, landDescription => ['mountain'], adjacent => [2, 3, 4],
      coordinates => [ [255,290], [234,254], [224,213], [239,168], [287,137], [355,135], [395,178], [398, 234], [371,284], [304,279] ],
      raceCoords  => [267,180],
      powerCoords => [346,173]
    },
    {
      population  => 1, landDescription => ['sea'], adjacent => [1, 4],
      coordinates => [ [224,213], [175,217], [132,184], [113,136], [131,91], [185,69], [242,77], [272,108], [287,137], [239,168] ],
      raceCoords  => [143,100],
      powerCoords => [218,82]
    },
    {
      population  => 1, landDescription => ['border', 'mountain'], adjacent => [1],
      coordinates => [ [269,399], [249,385], [232,360], [230,337], [236,305], [255,290], [304,279], [371,284], [405,303], [418,330], [411,356], [405,387], [396,399] ],
      raceCoords  => [297,316],
      powerCoords => [363,310]
    },
    {
      population  => 1, landDescription => ['coast'], adjacent => [1, 2],
      coordinates => [ [355,135], [365,96], [400,69], [446,62], [505,86], [523,138], [515,187], [487,218], [442,233], [398,234], [395,178] ],
      raceCoords  => [400,75],
      powerCoords => [465,137]
    }
  ]}
];

# игровые бонусы и штрафы
use constant ALCHEMIST_COINS_BONUS      => 2    ;
use constant ALCHEMIST_TOKENS_NUM       => 4    ;
use constant AMAZONS_CONQ_TOKENS_NUM    => 4    ;
use constant AMAZONS_TOKENS_NUM         => 6    ;
use constant AMAZONS_TOKENS_MAX         => 15   ;
use constant BERSERK_TOKENS_NUM         => 4    ;
use constant BIVOUACKING_TOKENS_NUM     => 5    ;
use constant COMMANDO_CONQ_TOKENS_NUM   => 1    ;
use constant COMMANDO_TOKENS_NUM        => 4    ;
use constant DECLINED_TOKENS_NUM        => 1    ;
use constant DEFEND_TOKENS_NUM          => 2    ;
use constant DIPLOMAT_TOKENS_NUM        => 5    ;
use constant DRAGON_MASTER_TOKENS_NUM   => 5    ;
use constant DWARVES_TOKENS_NUM         => 3    ;
use constant DWARVES_TOKENS_MAX         => 8    ;
use constant ELVES_LOOSE_TOKENS_NUM     => 0    ;
use constant ELVES_TOKENS_NUM           => 6    ;
use constant ELVES_TOKENS_MAX           => 11   ;
use constant ENCAMPMENTS_MAX            => 5    ;
use constant FLYING_TOKENS_NUM          => 5    ;
use constant FOREST_TOKENS_NUM          => 4    ;
use constant FORTIFIED_TOKENS_NUM       => 3    ;
use constant FORTRESS_MAX               => 6    ;
use constant GIANTS_CONQ_TOKENS_NUM     => 1    ;
use constant GIANTS_TOKENS_NUM          => 6    ;
use constant GIANTS_TOKENS_MAX          => 11   ;
use constant HALFLINGS_TOKENS_NUM       => 6    ;
use constant HALFLINGS_TOKENS_MAX       => 11   ;
use constant HEROES_MAX                 => 2    ;
use constant HEROIC_TOKENS_NUM          => 5    ;
use constant HILL_TOKENS_NUM            => 4    ;
use constant HUMANS_TOKENS_NUM          => 5    ;
use constant HUMANS_TOKENS_MAX          => 10   ;
use constant INITIAL_COINS_NUM          => 5    ;
use constant INITIAL_TOKENS_NUM         => undef;
use constant LOOSE_TOKENS_NUM           => -1   ;
use constant LOSTTRIBES_TOKENS_MAX      => 18   ;
use constant MERCHANT_TOKENS_NUM        => 2    ;
use constant MOUNTED_TOKENS_NUM         => 5    ;
use constant MOUNTED_CONQ_TOKENS_NUM    => 1    ;
use constant ORCS_TOKENS_NUM            => 5    ;
use constant ORCS_TOKENS_MAX            => 10   ;
use constant PILLAGING_TOKENS_NUM       => 5    ;
use constant RATMEN_TOKENS_NUM          => 8    ;
use constant RATMEN_TOKENS_MAX          => 13   ;
use constant SEAFARING_TOKENS_NUM       => 5    ;
use constant SKELETONS_TOKENS_NUM       => 6    ;
use constant SKELETONS_TOKENS_MAX       => 20   ;
use constant SORCERERS_TOKENS_NUM       => 5    ;
use constant SORCERERS_TOKENS_MAX       => 18   ;
use constant STOUT_TOKENS_NUM           => 4    ;
use constant SWAMP_TOKENS_NUM           => 4    ;
use constant TRITONS_CONQ_TOKENS_NUM    => 1    ;
use constant TRITONS_TOKENS_NUM         => 6    ;
use constant TRITONS_TOKENS_MAX         => 11   ;
use constant TROLLS_DEF_TOKENS_NUM      => 1    ;
use constant TROLLS_TOKENS_NUM          => 5    ;
use constant TROLLS_TOKENS_MAX          => 10   ;
use constant UNDERWORLD_CONQ_TOKENS_NUM => 1    ;
use constant UNDERWORLD_TOKENS_NUM      => 5    ;
use constant WEALTHY_COINS_NUM          => 7    ;
use constant WEALTHY_TOKENS_NUM         => 4    ;
use constant WIZARDS_TOKENS_NUM         => 5    ;
use constant WIZARDS_TOKENS_MAX         => 10   ;

# типы регионов
use constant REGION_TYPE_BORDER   => 'border'  ;
use constant REGION_TYPE_CAVERN   => 'cavern'  ;
use constant REGION_TYPE_COAST    => 'coast'   ;
use constant REGION_TYPE_FARMLAND => 'farmland';
use constant REGION_TYPE_FOREST   => 'forest'  ;
use constant REGION_TYPE_HILL     => 'hill'    ;
use constant REGION_TYPE_MAGIC    => 'magic'   ;
use constant REGION_TYPE_MINE     => 'mine'    ;
use constant REGION_TYPE_MOUNTAIN => 'mountain';
use constant REGION_TYPE_SEA      => 'sea'     ;
use constant REGION_TYPE_SWAMP    => 'swamp'   ;

# расы
use constant RACE_AMAZONS   => 'Amazons'  ;
use constant RACE_DWARVES   => 'Dwarves'  ;
use constant RACE_ELVES     => 'Elves'    ;
use constant RACE_GIANTS    => 'Giants'   ;
use constant RACE_HALFLINGS => 'Halflings';
use constant RACE_HUMANS    => 'Humans'   ;
use constant RACE_ORCS      => 'Orcs'     ;
use constant RACE_RATMEN    => 'Ratmen'   ;
use constant RACE_SKELETONS => 'Skeletons';
use constant RACE_SORCERERS => 'Sorcerers';
use constant RACE_TRITONS   => 'Tritons'  ;
use constant RACE_TROLLS    => 'Trolls'   ;
use constant RACE_WIZARDS   => 'Wizards'  ;

use constant RACES => [
  RACE_AMAZONS, RACE_DWARVES, RACE_ELVES, RACE_GIANTS, RACE_HALFLINGS,
  RACE_HUMANS, RACE_ORCS, RACE_RATMEN, RACE_SKELETONS, RACE_SORCERERS,
  RACE_TRITONS, RACE_TROLLS, RACE_WIZARDS
];

# специальные способности
use constant SP_ALCHEMIST     => 'Alchemist'   ;
use constant SP_BERSERK       => 'Berserk'     ;
use constant SP_BIVOUACKING   => 'Bivouacking' ;
use constant SP_COMMANDO      => 'Commando'    ;
use constant SP_DIPLOMAT      => 'Diplomat'    ;
use constant SP_DRAGON_MASTER => 'DragonMaster';
use constant SP_FLYING        => 'Flying'      ;
use constant SP_FOREST        => 'Forest'      ;
use constant SP_FORTIFIED     => 'Fortified'   ;
use constant SP_HEROIC        => 'Heroic'      ;
use constant SP_HILL          => 'Hill'        ;
use constant SP_MERCHANT      => 'Merchant'    ;
use constant SP_MOUNTED       => 'Mounted'     ;
use constant SP_PILLAGING     => 'Pillaging'   ;
use constant SP_SEAFARING     => 'Seafaring'   ;
use constant SP_STOUT         => 'Stout'       ;
use constant SP_SWAMP         => 'Swamp'       ;
use constant SP_UNDERWORLD    => 'Underworld'  ;
use constant SP_WEALTHY       => 'Wealthy'     ;

use constant SPECIAL_POWERS => [
  SP_ALCHEMIST, SP_BERSERK, SP_BIVOUACKING, SP_COMMANDO, SP_DIPLOMAT,
  SP_DRAGON_MASTER, SP_FLYING, SP_FOREST, SP_FORTIFIED, SP_HEROIC, SP_HILL,
  SP_MERCHANT, SP_MOUNTED, SP_PILLAGING, SP_SEAFARING, SP_STOUT, SP_SWAMP,
  SP_UNDERWORLD, SP_WEALTHY
];

use constant REGION_TYPES => [
  REGION_TYPE_BORDER, REGION_TYPE_CAVERN, REGION_TYPE_COAST, REGION_TYPE_FARMLAND,
  REGION_TYPE_FOREST, REGION_TYPE_HILL, REGION_TYPE_MAGIC,
  REGION_TYPE_MINE, REGION_TYPE_MOUNTAIN, REGION_TYPE_SEA, REGION_TYPE_SWAMP
];

# внутриигровые состояния игры
use constant GS_DEFEND             => 'defend'           ;
use constant GS_SELECT_RACE        => 'selectRace'       ;
use constant GS_BEFORE_CONQUEST    => 'beforeConquest'   ;
use constant GS_CONQUEST           => 'conquest'         ;
use constant GS_REDEPLOY           => 'redeploy'         ;
use constant GS_BEFORE_FINISH_TURN => 'finishTurn'       ;
use constant GS_FINISH_TURN        => 'beforeFinishTurn' ;
use constant GS_IS_OVER            => 'gameOver'         ;

1;

__END__
