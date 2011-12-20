var cmdErrors = {
  'alreadyInGame': 'Already in game',
  'badAction': 'Wrong action. May be you use old version of client or server',
  'badAttackedRace': "You can't enchant your own race",
  'badBodyOrMapId': 'Error while upload map image',
  'badCoordinates': 'Wrong coordinates in map region description',
  'badEncampmentsNum': 'Wrong encampments num',
  'badFileExtension': 'Bad upload file extension',
  'badFriend': "You can't friend with this player",
  'badFriendId': 'Wrong friend id. Try reload page',
  'badGameDescription': 'Wrong game description',
  'badGameId': 'Wrong game. Try reload page',
  'badGameName': 'Wrong game name',
  'badGameState': 'Wrong game state. Try reload page',
  'badJson': 'Unexpected error. May be you use old version of client or server',
  'badUsernameOrPassword': 'Wrong username or password',
  'badMapId': 'Wrong map. Try reload page',
  'badMapName': 'Wrong map name',
  'badMessageText': 'Wrong message text',
  'badMoneyAmount': 'Not enough money',
  'badPassword': 'Wrong password',
  'badPlayersNum': 'Wrong players number',
  'badPosition': 'Wrong token badge position',
  'badPowerCoordinates': 'Wrong power coordinates',
  'badRaceCoordinates': 'Wrong race coordinates',
  'badReadinessStatus': 'Wrong readiness status',
  'badRegion': 'Wrong region',
  'badRegionId': 'Wrong region identifier',
  'badRegions': 'Wrong regions',
  'badSetHeroCommand': 'Wrong heroes number',
  'badUserSid': 'Wrong user session. Try relogin',
  'badSince': 'Wrong "since" parameter value. Try reload page',
  'badStage': 'Wrong game stage for this command',
  'badTokensNum': 'Wrong tokens number',
  'badTurnsNum': 'Wrong turns number',
  'badUsername': 'Wrong username',
  'cannotEnchantDeclinedRace': "You can't enchant declined race",
  'gameNameTaken': 'This game name already taken',
  'mapNameTaken': 'This map name already taken',
  'noMoreTokensInStorageTray': 'No more tokens in storage tray',
  'noTokensForRedeployment': 'No tokens for redeployment',
  'notEnoughEncampmentsForRedeployment': 'Not enough encampments for redeployment',
  'notEnoughTokens': 'Not enough tokens',
  'notInGame': 'Not in game',
  'nothingToEnchant': 'Nothing to enchant',
  'regionIsImmune': 'Region is immune',
  'thereAreTokensInTheHand': 'You should redeploy all tokens to regions',
  'tooManyFortifieds': 'Too many forts on map',
  'tooManyFortifiedsInRegion': 'Too many forts in region',
  'tooManyPlayers': 'Too many players',
  'userHasNotRegions': 'User has not regions',
  'usernameTaken': 'Username already taken'
};

var races = {
  null: '/pics/raceNone.png',
  '': '/pics/raceNone.png',
  'Amazons': '/pics/raceAmazons.png',
  'Dwarves': '/pics/raceDwarves.png',
  'Elves': '/pics/raceElves.png',
  'Giants': '/pics/raceGiants.png',
  'Halflings': '/pics/raceHalflings.png',
  'Humans': '/pics/raceHumans.png',
  'Orcs': '/pics/raceOrcs.png',
  'Ratmen': '/pics/raceRatmen.png',
  'Skeletons': '/pics/raceSkeletons.png',
  'Sorcerers': '/pics/raceSorcerers.png',
  'Tritons': '/pics/raceTritons.png',
  'Trolls': '/pics/raceTrolls.png',
  'Wizards': '/pics/raceWizards.png'
};

var specialPowers = {
  null: '/pics/spNone.png',
  '': '/pics/spNone.png',
  'Alchemist': '/pics/spAlchemist.png',
  'Berserk': '/pics/spBerserk.png',
  'Bivouacking': '/pics/spBivouacking.png',
  'Commando': '/pics/spCommando.png',
  'Diplomat': '/pics/spDiplomat.png',
  'DragonMaster': '/pics/spDragonMaster.png',
  'Flying': '/pics/spFlying.png',
  'Forest': '/pics/spForest.png',
  'Fortified': '/pics/spFortified.png',
  'Heroic': '/pics/spHeroic.png',
  'Hill': '/pics/spHill.png',
  'Merchant': '/pics/spMerchant.png',
  'Mounted': '/pics/spMounted.png',
  'Pillaging': '/pics/spPillaging.png',
  'Seafaring': '/pics/spSeafaring.png',
  'Stout': '/pics/spStout.png',
  'Swamp': '/pics/spSwamp.png',
  'Underworld': '/pics/spUnderworld.png',
  'Wealthy': '/pics/spWealthy.png'
};

var tokens = {
  null: '/pics/tokenNone.png',
  '': '/pics/tokenNone.png',
  'Amazons': '/pics/tokenAmazons.png',
  'Dwarves': '/pics/tokenDwarves.png',
  'Elves': '/pics/tokenElves.png',
  'Giants': '/pics/tokenGiants.png',
  'Halflings': '/pics/tokenHalflings.png',
  'Humans': '/pics/tokenHumans.png',
  'Orcs': '/pics/tokenOrcs.png',
  'Ratmen': '/pics/tokenRatmen.png',
  'Skeletons': '/pics/tokenSkeletons.png',
  'Sorcerers': '/pics/tokenSorcerers.png',
  'Tritons': '/pics/tokenTritons.png',
  'Trolls': '/pics/tokenTrolls.png',
  'Wizards': '/pics/tokenWizard.png'
};

var objects = {
  'holeInTheGround': '/pics/objHoleInTheGround.png',
  'lair': '/pics/objLair.png',
  'encampment': '/pics/objEncampment.png',
  'dragon': '/pics/objDragon.png',
  'fortified': '/pics/objFortified.png',
  'hero': '/pics/objHero.png'
};

var gameStages = {
  null: ['', ''],
  '': ['', ''],
  'defend': ["Wait other players", "Let's defend, my friend!"],
  'selectRace': ["Wait other players", "So... You should select your path... or race"],
  'beforeConquest': ["Wait other players", "<table><tr><td>May be you want</td><td><div id='placeDecline'></div></td><td>your race?</td></tr></table>"],
  'conquest': ["Wait other players", "Do you want some fun? Let's conquer some regions"],
  'redeploy': ["Wait other players", "Place your warriors to the world"],
  'beforeFinishTurn': ["Wait other players", "Last actions"],
  'finishTurn': ["Wait other players", "Click finish-turn button, dude"],
  'gameOver': ["Oops!.. Game over", "Oops!.. Game over"]
};

const GST_WAIT    = 1;
const GST_BEGIN   = 0;
const GST_IN_GAME = 2;
const GST_FINISH  = 3;
const GST_EMPTY   = 4;

const GS_DEFEND             = 'defend';
const GS_SELECT_RACE        = 'selectRace';
const GS_BEFORE_CONQUEST    = 'beforeConquest';
const GS_CONQUEST           = 'conquest';
const GS_REDEPLOY           = 'redeploy';
const GS_BEFORE_FINISH_TURN = 'beforeFinishTurn';
const GS_FINISH_TURN        = 'finishTurn';
const GS_IS_OVER            = 'gameOver';
