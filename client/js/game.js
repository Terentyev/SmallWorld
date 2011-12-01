var playerInfo = null;
var lastRegionId = null;

var areaClickAction = areaWrong;
var tokenBadgeClickAction = tokenBadgeWrong;
var commitStageClickAction = commitStageWrong;

var askNumOkClick = null;


function areaClick(regionId) {
  areaClickAction(regionId);
}

function tokenBadgeClick(position) {
  tokenBadgeClickAction(position);
}

function commitStageClick() {
  commitStageClickAction();
}

function declineClick() {
  if (confirm('Do you really want decline you race "' + playerInfo.currentTokenBadge.raceName + '"?')) {
    cmdDecline();
  }
}

/*******************************************************************************
   *         Utils                                                             *
   ****************************************************************************/
function getRegState(regionId) {
  return data.game.map.regions[regionId].currentRegionState;
}

function askNumBox(text, onOk, value) {
  $("#divAskNumQuestion").html(text).trigger("update");
  $("#inputAskNum").attr("value", value);
  askNumOkClick = onOk;
  //$("#divAskNum").dialog({modal: true});
  showModal('#divAskNum');
}

function updatePlayerInfo(gs) {
  for (var i in gs.players) {
    if (gs.players[i].userId == data.playerId) {
      playerInfo = gs.players[i];
      return;
    }
  }
}

function notEqual(gs, game, attr) {
  // если атрибут простого типа (скаляр как бы)
  if (typeof(gs[attr]) == 'string' || (keys(gs[attr])).length == 0) {
    return gs[attr] != game[attr];
  }
  var k = keys(gs[attr]);
  for (var i in k) {
    if (notEqual(gs[attr], game[attr], k[i])) {
      return true;
    }
  }
  return false;
}

function mergeMember(gs, attr, actions, acts) {
  if (notEqual(gs, data.game, attr)) {
    data.game[attr] = gs[attr];
    for (var i in actions) {
      acts.push(actions[i]);
    }
  }
}

function mergeGameState(gs) {
  updatePlayerInfo(gs);
  if (data.game == null) {
    data.game = gs;
    changeGameStage();
    showGame();
    return;
  }

  var acts = [];
  mergeMember(gs, 'activePlayerId',     [showPlayers], acts);
  mergeMember(gs, 'stage',              [changeGameStage], acts);
  mergeMember(gs, 'visibleTokenBadges', [showBadges], acts);
  mergeMember(gs, 'map',                [showMapObjects], acts);
  mergeMember(gs, 'players',            [showPlayers], acts);
  for (var i in acts) {
    acts[i]();
  }
}

function changeGameStage() {
  showGameStage();
  areaClickAction = areaWrong;
  tokenBadgeClickAction = tokenBadgeWrong;
  commitStageClickAction = commitStageGetGameState;
  if (data.game.activePlayerId != data.playerId) {
    return;
  }

  commitStageClickAction = commitStageWrong;
  switch (data.game.stage) {
    case 'defend':
      areaClickAction = areaPlaceTokens;
      commitStageClickAction = commitStageDefend;
      break;
    case 'selectRace':
      tokenBadgeClickAction = tokenBadgeBuy;
      break;
    case 'beforeConquest':
      commitStageClickAction = commitStageBeforeConquest;
      areaClickAction = areaConquer;
      break;
    case 'conquest':
      areaClickAction = areaConquer;
      commitStageClickAction = commitStageConquest;
      break;
    case 'redeploy':
      areaClickAction = areaPlaceTokens;
      commitStageClickAction = commitStageRedeploy;
      break;
    case 'finishTurn':
      commitStageClickAction = commitStageFinishTurn;
      break;
    case 'gameOver':
      // TODO: show game results
      break;
  }
}

/*******************************************************************************
   *         Token badge actions                                               *
   ****************************************************************************/
function tokenBadgeWrong() {
  alert('Wrong action. Your race: ' + playerInfo.currentTokenBadge.raceName);
}

function tokenBadgeBuy(position) {
  if (position > playerInfo.coins) {
    alert('Not enough coins');
    return;
  }
  cmdSelectRace(position);
}

/*******************************************************************************
   *         Area actions                                                      *
   ****************************************************************************/
function areaWrong() {
  alert('Wrong action. Try: ' + gameStages[data.game.stage][data.game.activePlayerId == data.playerId ? 0 : 1]);
}

function areaConquer(regionId) {
  // TODO: do needed checks
  data.game.stage = 'conquest';
  changeGameStage();
  cmdConquer(regionId);
}

function areaPlaceTokens(regionId) {
  // TODO: do needed checks
  // ask player how much tokens
  var regState = getRegState(regionId);
  if (regState.tokenBadgeId != playerInfo.currentTokenBadge.tokenBadgeId) {
    alert('Wrong region');
    return;
  }

  lastRegionId = regionId;
  askNumBox('How much tokens deploy on region?',
            deployRegion,
            regState.tokensNum);
}

function deployRegion() {
  var v = $("#inputAskNum").attr("value");
  var regState = getRegState(lastRegionId);
  if (!isUInt(v)) {
    $('#divAskNumError').html('You must enter integer').trigger('update');;
    return;
  }

  v = parseInt(v);
  if (v - regState.tokensNum > playerInfo.tokensInHand) {
    $('#divAskNumError').html('Not enough tokens in hand').trigger('update');;
    return;
  }

  playerInfo.tokensInHand -= v - regState.tokensNum;
  regState.tokensNum = v;
  $("#aTokensNum" + lastRegionId).html(regState.tokensNum).trigger("update");
  $("#aTokensInHand").html(playerInfo.tokensInHand).trigger("update");
  $.modal.close();
}

/*******************************************************************************
   *         Commit stage actions                                              *
   ****************************************************************************/
function commitStageWrong() {
  alert('Wrong action. Try: ' + gameStages[data.game.stage][data.game.activePlayerId == data.playerId ? 0 : 1]);
}

function commitStageDefend() {
  checkDeploy(cmdDefend);
}

function commitStageBeforeConquest() {
  data.game.stage = 'conquest';
  changeGameStage();
}

function commitStageConquest() {
  data.game.stage = 'redeploy';
  changeGameStage();
}

function commitStageRedeploy() {
  checkDeploy(cmdRedeploy);
}

function commitStageFinishTurn() {
  // TODO: do needed checks
  cmdFinishTurn();
}

function commitStageGetGameState() {
  cmdGetGameState();
}

/*******************************************************************************
   *         Some checks                                                       *
   ****************************************************************************/
function checkDeploy(cmd) {
  var regions = null;
  for (var i in data.game.map.regions) {
    var cur = data.game.map.regions[i].currentRegionState;
    if (cur.tokenBadgeId != playerInfo.currentTokenBadge.tokenBadgeId) {
      continue;
    }
    if (regions == null) {
      regions = new Array();
    }
    if (cur.tokensNum != 0) {
      regions.push({ regionId: parseInt(i), tokensNum: cur.tokensNum });
    }
  }

  if (regions == null) {
    cmdGetGameState();
  }
  else if (regions.length != 0) {
    cmd(regions);
  }
  else {
    alert('You should place you tokens in the world');
  }
}
