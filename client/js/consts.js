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

var races = ['Amazons', 'Dwarves', 'Elves', 'Giants', 'Halflings', 'Humans', 'Orcs', 'Ratmen', 'Skeletons',
             'Sorcerers', 'Tritons', 'Trolls', 'Wizards'];

var raceDescription = {
  'None': '',
  'Amazons': 'Four of your Amazon tokens may only be used for conquest, not for defense. So you start each turn with +4 Amazon token. At the end of each Troop Redeployments four tokens removed from the map, and back to your hand at the start of next turn.',
  'Dwarves': 'Each Mine Region your Dwarves occupy is worth 1 bonus Victory coin, at the end of your turn. This power is kept even when the Dwarves are In Decline',
  'Elves': 'When the enemy conquers one of your Regions, keep all your Elf tokens in hand for redeployment, rather than discarding 1 Elf token back into the storage tray',
  'Giants': 'Your Giants may conquer any Region adjacent to a Mountain Region they occupy at a cost of 1 less Giant token than normal. A minimum of 1 Giant token is still required',
  'Halflings': 'Your Halfling tokens may enter the map through any Region, not just border ones. Place a Hole-in-the-Ground in each of the first 2 Regions you conquer, to make them immune to enemy conquests as well as racial and special powers. You lost your Holes-in-the-Ground when your Halflings go into Decline, or if you choose to abandon a Region containing a Hole-in-the-Ground',
  'Humans': 'Each Farmland Region your Humans occupy is worth 1 bonus Victory coin, at the end of your turn',
  'Orcs': 'Each not empty Region your Orcs conquered this turn is worth 1 bonus Victory coin, at the end of your turn',
  'Ratmen': 'No Race benefit; their sheer number of tokens is enough!',
  'Skeletons': 'During your Troop Redeployment, you receive 1 new Skeleton token from the storage tray for every 2 non-empty Regions you conquered this turn, and add it to the troops you redeploy at the end of your turn. If there are no more tokens in the storage tray, you do not receive any additional tokens',
  'Sorcerers': 'Once per turn, your Sorcerers can conquer adjacent Region by substituting one of your opponent\'s Active tokens with one of your own taken from the storage tray. If there are no more tokens in the storage tray, then you cannot conquer a new Region in this way. The token your Sorcerers replaces must be the only race token in its Region',
  'Tritons': 'Your Tritons may conquer all Coastal Regions (those bordering a Sea or Lake) at a cost of 1 less Triton token than normal. A minimum of 1 Triton token is still required',
  'Trolls': 'Place a Troll\'s Lair in each Region your Trolls occupy. The Troll\'s Lair augments your region\'s defense by 1, and stays in the Region even after your Trolls go into Decline. Remove the Troll\'s Lair if you abandon the Region or when an enemy conquers it',
  'Wizards': 'Each Magic Region your Wizards occupy is worth 1 bonus Victory coin, at the end of your turn'
};

var powerDescription = {
  null: '',
  '': '',
  'Alchemist': 'Collect 2 bonus Victory coins at the end of each turn your race hasn\'t yet gone into Decline',
  'Berserk': 'You may use the Reinforcement die before each of your conquests, rather than just the last one of your turn. Roll the die first; select the Region you wish to conquer; then place the required number of Race tokens (minus the die results) there. If you do not have enough tokens left, this is your final conquest attempt for the turn. As usual, a minimum of 1 token is still required to attempt the conquest',
  'Bivouacking': 'Deploy the 5 Encampment tokens in any of your Region(s), during your Troop Redeployment phase. Each Encampment counts as 1 Race token toward the defense of the Region in which it is placed (thereby possibly protecting a single Race token with an Encampment from the Sorcerer\'s Special Power). Multiple encampments may be placed in the same Region to obtain a higher defense bonus',
  'Commando': 'You may conquer any adjacent Region with 1 less Race token than normal. A minimum of 1 token is still required',
  'Diplomat': 'At the end of your turn, you may select one opponent whose Active race you did not attack this turn as your ally. You are now at peace with him and he cannot attack your active race until your next turn. You may change allies each turn, or stay at peace with the same opponent. Tokens In Decline are not impacted',
  'DragonMaster': 'Once per turn, you may conquer a Region using a single Race token, regardless of the number of enemy tokens defending it. Once conquered, place your Dragon there. The Region is now immune to enemy conquests as well as to their racial and special powers until your Dragon moves. During each new turn, you may move your Dragon to a different Region you wish to conquer. Your Dragon disappears when you go into Decline',
  'Flying': 'You may conquer any Region of the map except Seas. These Regions do not need to be adjacent or contiguous to ones you already occupy',
  'Forest': 'Collect 1 bonus Victory coin for each Forest Region you occupy at turn\'s end',
  'Fortified': 'Once per turn, place 1 Fortress in a Region you occupy. The Fortress is worth 1 bonus Victory coin at turn\'s end, unless you leave or are In Decline. The Fortress also augments your Region\'s defense by 1, even if you leave or are In Decline. Remove the Fortress if you abandon the Region or when an enemy conquers it. There can only ever be a maximum of 1 Fortress per Region, and a maximum of 6 Fortresses on the map',
  'Heroic': 'At the end of your turn, place each of your 2 Heroes in 2 different Regions you occupy These 2 Regions are immune to enemy conquests as well as to their racial and special powers until your Heroes move. Your Heroes disappear when you go into Decline',
  'Hill': 'Collect 1 bonus Victory coin for each Hill Region you occupy at turn\'s end',
  'Merchant': 'Collect 1 bonus Victory coin for any Region you occupy at turn\'s end',
  'Mounted': 'You may conquer any Hill or Farmland Region with 1 less Race token than normal. A minimum of 1 token is still required',
  'Pillaging': 'Each non-empty Region you conquer this turn is worth 1 bonus Victory coin at turn\'s end',
  'Seafaring': 'You can consider the Seas and Lakes as empty Regions you may conquer. You keep these Regions even once you go into Decline, and continue scoring for them for as long as you have tokens there',
  'Stout': 'You may go In Decline at the end of a regular turn of conquests, after scoring, instead of spending an entire turn going into Decline',
  'Swamp': 'Collect 1 bonus Victory coin for each Swamp Region you occupy at turn\'s end',
  'Underworld': 'You may conquer any Region with a Cavern with 1 less Race token than normal. A minimum of 1 token is still required. All Regions with a Cavern are also considered adjacent to each other for your conquest purposes',
  'Wealthy': 'Collect 7 bonus Victory coins, once only, at the end of your first turn'
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

var objects = {
  'holeInTheGround': {'src': '/pics/objHoleInTheGround.png', 'title': 'Hole'},
  //'lair': '/pics/objLair.png',
  'dragon': {'src': '/pics/objDragon.png', 'title': 'Dragon'},
  'fortified': {'src': '/pics/objFortified.png', 'title': 'Fortress'},
  'hero': {'src': '/pics/objHero.png', 'title': 'Hero'},
  'encampment': {'src': '/pics/objEncampment.png', 'title': 'Encampment'}
};

var land = {
  'sea': "url('./pics/sea.png')",
  'mountain': "url('./pics/mountain.png')",
  'forest': "url('./pics/forest.png')",
  'swamp': "url('./pics/swamp.png')",
  'hill': "url('./pics/hill.png')",
  'farmland': "url('./pics/farmland.png')"
}
const maxMessagesCount = 100;
const autoFinishTurn = 1;

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

var stageNames = {
  'defend':           'Defend',
  'selectRace':       'Select race',
  'beforeConquest':   'Conquest',
  'conquest':         'Conquest',
  'redeploy':         'Redeploy',
  'beforeFinishTurn': 'Finish Turn',
  'finishTurn':       'Finish Turn',
  'gameOver':         'Game over'
};

var stageTitles = {
  'defend': 'Click on your region to redeploy tokens on it. This region not have to be adjacent(if possible) to region they fled from',
  'selectRace': 'Select pair race/special power in left column',
  'conquest': 'Click on region to try conquer it',
  'redeploy': 'Click on your region to change number of tokens on it and place or remove game objects'
};

const LE_FINISH_TURN    =  4;
const LE_SELECT_RACE    =  5;
const LE_CONQUER        =  6;
const LE_DECLINE        =  7;
const LE_REDEPLOY       =  8;
const LE_THROW_DICE     =  9;
const LE_DEFEND         = 12;
const LE_SELECT_FRIEND  = 13;
const LE_FAILED_CONQUER = 14;

const HEROES_MAX = 2;
const ENCAMPMENTS_MAX = 5;
const FORTRESSES_MAX = 6;

const actionDivs = ['#divDecline', '#divEnchant', '#divDragonAttack', '#divThrowDice', '#divConquest', '#divSelectFriend'];

const tokenWidth = 40;
const tokenHeight = 40;
const coinWidth = 16;
const coinHeight = 16;
const coinStep = 12;
var regionAttr = {
  'stroke': 'gray',
  'stroke-width': 2,
  'stroke-linejoin': 'round'
};

var textAttr = {
  'font-size': 14,
  'stroke': "white",
  'fill': "white"
};

const modalSize = {
  'defaultWidth': 420,
  'defaultHeight': 160,
  'minHeight': 120,
  'lineHeight': 28
}
