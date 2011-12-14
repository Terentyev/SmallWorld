var place = null;
var defend = null;

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

function selectFriend() {
  var pls = '';
  for (var i in data.game.players) {
    var cur = data.game.players[i];
    if (player.isHe(cur.userId)) continue;
    pls += addOption(cur.userId, cur.username);
  }
  $('#selectPlayers').html(pls).triggel('update');
  showModal('#divSelectFriend');
}

function dragonAttack() {
  // TODO
  if (areaClick != areaDragonAttack) {
    areaClick = areaDragonAttack;
    $('#txtDragonAttack').css('color', '#FF0000');
    alert('Now click on region for dragon attack');
  }
  else {
    areaClick = areaConquer;
    $('#txtDragonAttack').css('color', '#FFFFFF');
  }
}

function decline() {
  if (confirm('Do you really want decline you race "' + player.curRace() + '"?')) {
    cmdDecline();
  }
}

function enchant() {
  // TODO
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
  showModal('#divAskNum');
}

function updatePlayerInfo(gs) {
  player = new Player(gs, data.playerId);
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
      var found = false;
      for (var j in acts) {
        if (acts[j] == actions[i]) {
          found = true;
          break;
        }
      }
      if (!found) {
        acts.push(actions[i]);
      }
    }
  }
}

function mergeGameState(gs) {
  updatePlayerInfo(gs);
  if (data.game == null || data.game.state != gs.state) {
    data.game = gs;
    changeGameStage();
    showGame();
    return;
  }

  var acts = [];
  mergeMember(gs, 'activePlayerId',     [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'stage',              [changeGameStage], acts);
  mergeMember(gs, 'visibleTokenBadges', [showBadges], acts);
  mergeMember(gs, 'map',                [showMapObjects], acts);
  mergeMember(gs, 'players',            [showPlayers], acts);
  for (var i in acts) {
    acts[i]();
  }
}

function changeGameStage(stage) {
  if (stage != null) {
    data.game.stage = stage;
  }
  if (data.game.stage == 'gameOver') {
    showScores();
    return;
  }
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
      defend = { regions: [], regionId: null };
      areaClickAction = areaDefend;
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
    case 'beforeFinishTurn':
      commitStageClickAction = commitStageFinishTurn;
      // TODO: show special power button
      break
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
  alert('Wrong action. Your race: ' + player.curRace());
}

function tokenBadgeBuy(position) {
  if (position > player.coins()) {
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
  changeGameStage('conquest');
  if (!player.canAttack(regionId)) {
    return;
  }
  player.setRegionId(regionId);
  cmdConquer(regionId);
}

function areaDragonAttack(regionId) {
  changeGameStage('conquest');
  if (!player.canDragonAttack(regionId)) {
    return;
  }
  player.setRegionId(regionId);
  cmdDragonAttack(regionId);
  dragonAttack();
}

function areaPlaceTokens(regionId) {
  // TODO: do needed checks
  place = new Region(regionId);
  if (!place.isOwned(player.curTokenBadgeId())) {
    alert('Wrong region');
    return;
  }

  askNumBox('How much tokens deploy on region?',
            deployRegion,
            place.tokens());
}

function deployRegion() {
  if (checkAskNumber()) return;
  var v = parseInt($("#inputAskNum").attr("value"));
  if (checkEnough(v - place.tokens() > player.tokens(), '#divAskNumError')) return;

  player.addTokens(place.tokens() - v);
  place.rmTokens(place.tokens() - v);
  $.modal.close();
}

function areaDefend(regionId) {
  // TODO: do needed checks
  var regState = getRegState(regionId);
  if (regState.tokenBadgeId != player.curTokenBadgeId()) {
    alert('Wrong region');
    return;
  }

  // TODO: check adjacent regions
  /*for (var i in data.game.map.regions) {
    if (i == regionId) continue;
    var cur = data.game.map.regions[i];
    if (
  }*/
  defend.regionId = regionId;
  if (defend.regions[regionId] == null) defend.regions[regionId] = 0;
  askNumBox('How much tokens deploy on region on defend?',
            defendRegion,
            defend.regions[regionId]);
}

function defendRegion() {
  if (checkAskNumber()) return;
  var v = parseInt($('#inputAskNum').attr('value'));
  if (checkEnough(v - defend.regions[defend.regionId] > player.tokens(), '#divAskNumError')) return;
  var regState = getRegState(defend.regionId);

  player.addTokens(defend.regions[defend.regionId] - v);
  defend.regions[defend.regionId] = v;
  $('#aTokensNum' + defend.regionId).html($.sprintf(
        '%d <a color="#FF0000">+%d</a>', regState.tokensNum, defend.regions[defend.regionId])).trigger('update');
  $.modal.close();
}

/*******************************************************************************
   *         Commit stage actions                                              *
   ****************************************************************************/
function commitStageWrong() {
  alert('Wrong action. Try: ' + gameStages[data.game.stage][data.game.activePlayerId == data.playerId ? 0 : 1]);
}

function commitStageDefend() {
  checkDeploy(
    cmdDefend,
    function(i, regions) {
      if (defend.regions[i] != 0) regions.push({ regionId: parseInt(i), tokensNum: defend.regions[i] })
    });
}

function commitStageBeforeConquest() {
  changeGameStage('conquest');
}

function commitStageConquest() {
  player.beforeRedeploy();
  changeGameStage('redeploy');
}

function commitStageRedeploy() {
  checkDeploy(
    cmdRedeploy,
    function(i, regions) {
      var cur = data.game.map.regions[i].currentRegionState;
      if (cur.tokensNum != 0) regions.push({ regionId: parseInt(i), tokensNum: cur.tokensNum })
    });
}

function commitStageFinishTurn() {
  // TODO: do needed checks
  cmdFinishTurn();
}

function commitStageGetGameState() {
  cmdGetGameState();
}

/*******************************************************************************
   *         Special powers commits                                            *
   ****************************************************************************/
function commitSelectFriend() {
  cmdSelectFriend($('#selectPlayers').attr('value'));
}

/*******************************************************************************
   *         Some checks                                                       *
   ****************************************************************************/
function checkDeploy(cmd, add) {
  var regions = null;
  for (var i in data.game.map.regions) {
    var cur = data.game.map.regions[i].currentRegionState;
    if (cur.tokenBadgeId != player.curTokenBadgeId()) continue;
    if (regions == null) {
      regions = [];
    }
    add(i, regions);
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
