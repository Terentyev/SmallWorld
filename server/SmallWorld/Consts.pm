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
use constant R_BAD_COORDINATES              => 'badCoordinates'                     ;
use constant R_BAD_ENCAMPMENTS_NUM          => 'badEncampmentsNum'                  ;
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
use constant R_BAD_NUM_OF_PLAYERS           => 'badNumberOfPlayers'                 ;
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
    R_BAD_REGION, R_REGION_IS_IMMUNE
  ],
  createDefaultMaps  => [],
  createGame         => [R_BAD_SID, R_GAME_NAME_TAKEN, R_BAD_MAP_ID, R_ALREADY_IN_GAME],
  decline            => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID # R_BAD_GAME_STATE
  ],
  defend             => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_NOT_ENOUGH_TOKENS, R_THERE_ARE_TOKENS_IN_THE_HAND
  ],
  dragonAttack       => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION
  ],
  enchant            => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_BAD_ATTACKED_RACE, R_NOTHING_TO_ENCHANT, R_CANNOT_ENCHANT,
    R_NO_MORE_TOKENS_IN_STORAGE
  ],
  finishTurn         => [R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE], # R_BAD_GAME_STATE
  getGameList        => [R_BAD_SID],
  getGameState       => [],
  getMapList         => [R_BAD_SID],
  getMessages        => [],
  joinGame           => [R_BAD_SID, R_BAD_GAME_ID, R_BAD_GAME_STATE, R_ALREADY_IN_GAME, R_TOO_MANY_PLAYERS],
  leaveGame          => [R_BAD_SID, R_NOT_IN_GAME],
  login              => [R_BAD_LOGIN],
  logout             => [R_BAD_SID],
  redeploy           => [
    R_BAD_SID, R_NOT_IN_GAME, R_BAD_STAGE, R_BAD_REGION_ID, # R_BAD_GAME_STATE
    R_BAD_REGION, R_USER_HAS_NOT_REGIONS, R_BAD_TOKENS_NUM,
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
      mandatory => 1
    },
    {
      name => 'regionId',
      type => 'int',
      min => 1, # нумерация регионов начинается с 1 (stupid youth!!!)
      mandatory => 1,
      errorCode => R_BAD_REGION_ID
    }
  ],
  decline =>[ {name => 'sid', type => 'int', mandatory => 1} ],
  finishTurn => [ {name => 'sid', type => 'int', mandatory => 1} ],
  redeploy => [
    {name => 'sid', type => 'int', mandatory => 1},
    {name => 'regions', type => 'list', mandatory => 1},
    {name => 'encampments', type => 'list', mandatory => 0},
    {name => 'fortified', type => 'hash', mandatory => 0},
    {name => 'heroes', type => 'list', mandatory => 0}
  ],
  defend => [
    {name => 'sid', type => 'int', mandatory => 1},
    {name => 'regions', type => 'list', mandatory => 1}
  ],
  enchant => [
    {name => 'sid', type => 'int', mandatory => 1},
    {name => 'regionId', type => 'int', mandatory => 1}
  ],
  resetServer => [ {name => 'sid', type => 'int', mandatory => 0} ],
  throwDice => [
    {name => 'sid', type => 'int', mandatory => 1},
    {name => 'dice', type => 'int', mandatory => 0}
  ],
  dragonAttack => [
    {name => 'sid', type => 'int', mandatory => 1},
    {name => 'regionId', type => 'int', mandatory => 1}
  ],
  selectFriend => [
    {name => 'sid', type => 'int', mandatory => 1},
    {name => 'friendId', type => 'int', mandatory => 1}
  ],
  getGameState => [
    {
      name => 'sid',
      type => 'int',
      mandatory => 1,
      errorCode => R_BAD_SID
    }
  ]
};

use constant DB_GENERATORS_NAMES => ['GEN_MAP_ID', 'GEN_GAME_ID', 'GEN_MESSAGE_ID', 'GEN_SID', 'GEN_PLAYER_ID', 'GEN_CONNECTION_ID'];
use constant DB_TABLES_NAMES     => ['PLAYERS', 'MAPS', 'GAMES', 'MESSAGES', 'CONNECTIONS']                                         ;

use constant DEFAULT_MAPS => [
  {mapName => 'Are you lucky?', playersNum => 2, turnsNum => 5, regions =>[
    {
      population  => 1, landDescription => ['border', 'coast'], adjacent => [2],
      coordinates => [ [255,290], [234,254], [224,213], [239,168], [287,137], [355,135], [395,178], [371,284], [304,279] ],
      raceCoords  => [267,216],
      powerCoords => [346,208]
    },
    {
      population  => 0, landDescription => ['border'], adjacent => [1],
      coordinates => [ [255,290], [234,254], [224,213], [239,168], [287,137], [355,135], [395,178], [371,284], [304,279] ],
      raceCoords  => [267,216],
      powerCoords => [346,208]
    },
  ]},
  {mapName => 'Cheburashka', playersNum => 3, turnsNum => 5, regions => [
    {
      population  => 1, landDescription => ['mountain'], adjacent => [2, 3, 4],
      coordinates => [ [255,290], [234,254], [224,213], [239,168], [287,137], [355,135], [395,178], [371,284], [304,279] ],
      raceCoords  => [267,216],
      powerCoords => [346,208]
    },
    {
      population  => 1, landDescription => ['sea'], adjacent => [1, 4],
      coordinates => [ [224,213], [175,217], [132,184], [113,136], [131,91], [185,69], [242,77], [272,108], [287,137], [239,168] ],
      raceCoords  => [143,133],
      powerCoords => [218,117]
    },
    {
      population  => 1, landDescription => ['border', 'mountain'], adjacent => [1],
      coordinates => [ [269,399], [249,385], [232,360], [230,337], [236,305], [255,290], [304,279], [371,284], [405,303], [418,330], [411,356], [405,387], [396,399] ],
      raceCoords  => [297,351],
      powerCoords => [363,345]
    },
    {
      population  => 1, landDescription => ['coast'], adjacent => [1, 2],
      coordinates => [ [355,135], [365,96], [400,69], [446,62], [505,86], [523,138], [515,187], [487,218], [442,233], [398,234], [395,178] ],
      raceCoords  => [400,110],
      powerCoords => [465,172]
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
use constant COMMANDO_CONQ_TOKENS_NUM   => -1   ;
use constant COMMANDO_TOKENS_NUM        => 4    ;
use constant DECLINED_TOKENS_NUM        => 1    ;
use constant DEFEND_TOKENS_NUM          => 2    ;
use constant DIPLOMAT_TOKENS_NUM        => 5    ;
use constant DRAGON_MASTER_TOKENS_NUM   => 5    ;
use constant DWARVES_TOKENS_NUM         => 3    ;
use constant DWARVES_TOKENS_MAX         => 8    ;
use constant ELVES_LOOSE_TOKENS_NUM     => 1    ;
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
use constant MOUNTED_CONQ_TOKENS_NUM    => -1   ;
use constant ORCS_TOKENS_NUM            => 5    ;
use constant ORCS_TOKENS_MAX            => 10   ;
use constant PILLAGING_TOKENS_NUM       => 5    ;
use constant RATMEN_TOKENS_NUM          => 8    ;
use constant RATMEN_TOKENS_MAX          => 13   ;
use constant SEAFARING_TOKENS_NUM       => 5    ;
use constant SKELETONS_RED_TOKENS_NUM   => 1    ;
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
use constant UNDERWORLD_CONQ_TOKENS_NUM => -1   ;
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
use constant REGION_TYPE_LAKE     => 'lake'    ;
use constant REGION_TYPE_MAGIC    => 'magic'   ;
use constant REGION_TYPE_MINE     => 'mine'    ;
use constant REGION_TYPE_MOUNTAIN => 'mountain';
use constant REGION_TYPE_SEA      => 'sea'     ;
use constant REGION_TYPE_SWAMP    => 'swamp'   ;

# расы
use constant RACE_AMAZONS   => 'amazons'  ;
use constant RACE_DWARVES   => 'dwarves'  ;
use constant RACE_ELVES     => 'elves'    ;
use constant RACE_GIANTS    => 'giants'   ;
use constant RACE_HALFLINGS => 'halflings';
use constant RACE_HUMANS    => 'humans'   ;
use constant RACE_ORCS      => 'orcs'     ;
use constant RACE_RATMEN    => 'ratmen'   ;
use constant RACE_SKELETONS => 'skeletons';
use constant RACE_SORCERERS => 'sorcerers';
use constant RACE_TRITONS   => 'tritons'  ;
use constant RACE_TROLLS    => 'trolls'   ;
use constant RACE_WIZARDS   => 'wizards'  ;

use constant RACES => [
  RACE_AMAZONS, RACE_DWARVES, RACE_ELVES, RACE_GIANTS, RACE_HALFLINGS,
  RACE_HUMANS, RACE_ORCS, RACE_RATMEN, RACE_SKELETONS, RACE_SORCERERS,
  RACE_TRITONS, RACE_TROLLS, RACE_WIZARDS
];

# специальные способности
use constant SP_ALCHEMIST     => 'alchemist'   ;
use constant SP_BERSERK       => 'berserk'     ;
use constant SP_BIVOUACKING   => 'bivouacking' ;
use constant SP_COMMANDO      => 'commando'    ;
use constant SP_DIPLOMAT      => 'diplomat'    ;
use constant SP_DRAGON_MASTER => 'dragonMaster';
use constant SP_FLYING        => 'flying'      ;
use constant SP_FOREST        => 'forest'      ;
use constant SP_FORTIFIED     => 'fortified'   ;
use constant SP_HEROIC        => 'heroic'      ;
use constant SP_HILL          => 'hill'        ;
use constant SP_MERCHANT      => 'merchant'    ;
use constant SP_MOUNTED       => 'mounted'     ;
use constant SP_PILLAGING     => 'pillaging'   ;
use constant SP_SEAFARING     => 'seafaring'   ;
use constant SP_STOUT         => 'stout'       ;
use constant SP_SWAMP         => 'swamp'       ;
use constant SP_UNDERWORLD    => 'underworld'  ;
use constant SP_WEALTHY       => 'wealthy'     ;

use constant SPECIAL_POWERS => [
  SP_ALCHEMIST, SP_BERSERK, SP_BIVOUACKING, SP_COMMANDO, SP_DIPLOMAT,
  SP_DRAGON_MASTER, SP_FLYING, SP_FOREST, SP_FORTIFIED, SP_HEROIC, SP_HILL,
  SP_MERCHANT, SP_MOUNTED, SP_PILLAGING, SP_SEAFARING, SP_STOUT, SP_SWAMP,
  SP_UNDERWORLD, SP_WEALTHY
];

use constant REGION_TYPES => [
  REGION_TYPE_BORDER, REGION_TYPE_CAVERN, REGION_TYPE_COAST, REGION_TYPE_FARMLAND,
  REGION_TYPE_FOREST, REGION_TYPE_HILL, REGION_TYPE_LAKE, REGION_TYPE_MAGIC, 
  REGION_TYPE_MINE, REGION_TYPE_MOUNTAIN, REGION_TYPE_SEA, REGION_TYPE_SWAMP
];

# внутриигровые состояния игры
use constant GS_DEFEND      => 'defend'     ;
use constant GS_SELECT_RACE => 'selectRace' ;
use constant GS_CONQUEST    => 'conquest'   ;
use constant GS_REDEPLOY    => 'redeploy'   ;
use constant GS_FINISH_TURN => 'finishTurn' ;
use constant GS_IS_OVER     => 'gameOver'   ;

__END__

1;
