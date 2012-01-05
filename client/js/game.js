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
  $('#selectPlayers').html(pls).trigger('update');
}

function dragonAttack() {
  if (!$('#checkBoxDragon').is(':disabled') && $('#checkBoxDragon').is(':checked'))
    areaClickAction = areaDragonAttack;
  else
    areaClickAction = areaConquer;
}

function decline() {
  if (confirm('Do you really want to decline your race "' + player.curRace() + '"?')) {
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
  player = new Player(data.playerId, gs);
}

function notEqual(gs, game, attr) {
  if (game[attr] == null) return true;
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

function prepare(gs) {
  // для совместимости
  if (gs.stage != null) return;
  // можно смотреть также в SmallWorld::Game->getStageForGameState (он работает
  // однозначно правильно (т. к. тастировался)
  switch (gs.state) {
    case GST_WAIT:
      break;
    case GST_BEGIN:
      gs.stage = GS_SELECT_RACE;
      break;
    case GST_IN_GAME:
      if (gs.defendingInfo != null && gs.defendingInfo != null) {
        gs.stage = GS_DEFEND;
        return;
      }
      switch (gs.lastEvent) {
        case LE_THROW_DICE:
        case LE_CONQUER:
        case LE_DEFEND:
        case LE_SELECT_RACE:
          gs.stage = GS_CONQUEST;
          break;
        case LE_SELECT_FRIEND:
        case LE_DECLINE:
          gs.stage = GS_FINISH_TURN;
          break;
        case LE_REDEPLOY:
          gs.stage = GS_BEFORE_FINISH_TURN;
          break;
        case LE_FAILED_CONQUER:
          gs.stage = player.myRegions().length > 0
            ? GS_REDEPLOY
            : GS_BEFORE_FINISH_TURN;
          break;
        //case LE_FINISH_TURN:
        default:
          gs.stage = player.haveActiveRace()
            ? GS_BEFORE_CONQUEST
            : GS_SELECT_RACE;
          break;
      }
      break;
    case ST_FINISH:
      gs.stage = GS_IS_OVER;
      break;
  }
}

function mergeGameState(gs) {
  updatePlayerInfo(gs);
  prepare(gs);
  if (data.game == null || data.game.state != gs.state) {
    data.game = gs;
    changeGameStage();
    showGame();
    return;
  }
  var acts = [];
  mergeMember(gs, 'activePlayerId',     [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'defendingInfo',      [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'friendInfo',         [showPlayers],                  acts);
  mergeMember(gs, 'dragonAttacked',     [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'enchanted',          [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'stage',              [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'visibleTokenBadges', [showBadges],                   acts);
  mergeMember(gs, 'map',                [showMapObjects],               acts);
  mergeMember(gs, 'players',            [showPlayers],                  acts);
  for (var i in acts) {
    acts[i]();
  }
  updatePlayerInfo(data.game);
}

function setGameStage(stage) {
  var gs = clone(data.game);
  gs.stage = stage;
  mergeGameState(gs);
}

function changeGameStage(stage) {
  if (stage != null) {
    data.game.stage = stage;
  }
  showGameStage();
  if (data.game.stage == 'gameOver') {
    showScores();
    return;
  }
  areaClickAction = areaWrong;
  tokenBadgeClickAction = tokenBadgeWrong;
  commitStageClickAction = commitStageGetGameState;
  if (!player.isActive()) {
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
  alert('Wrong action');
}

function areaConquer(regionId) {
  if (!player.canAttack(regionId)) {
    setGameStage(GS_CONQUEST);
    return;
  }
  var r = new Region(regionId);
  setGameStage(r.needDefend() ? GS_DEFEND: GS_CONQUEST);
  player.setRegionId(regionId);
  cmdConquer(regionId);
}

function areaDragonAttack(regionId) {
  if (!player.canDragonAttack(regionId)) {
    return;
    setGameStage(GS_CONQUEST);
  }
  var r = new Region(regionId);
  setGameStage(r.needDefend() ? GS_DEFEND: GS_CONQUEST);
  player.setRegionId(regionId);
  //dragonAttack();
  cmdDragonAttack(regionId);
}

function areaPlaceTokens(regionId) {
  // TODO: do needed checks
  place = new Region(regionId);
  if (!place.isOwned(player.curTokenBadgeId())) {
    alert('Wrong region');
    return;
  }

  switch (player.curPower()) {
    case 'Bivouacking':
      var s = '', count = place.get('encampment');
      var pattern = $.sprintf("#selectEncampments [value='%s']", count);;
      for (var i = 0; i <= count + player.encampments(); ++i) {
        s += addOption(i, i);
      }
      $('#selectEncampments').html(s);
      $(pattern).attr("selected", "selected");
      break;
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
  var region = new Region(regionId);
  if (!region.isOwned(player.curTokenBadgeId())) {
    alert('Wrong region');
    return;
  }

  // TODO: check adjacent regions
  var loose = new Region(data.game.defendingInfo.regionId);
  if (loose.isAdjacent(regionId)) {
    for (var i in data.game.map.regions) {
      var cur = new Region(i);
      if (loose.isAdjacent(i) || !cur.isOwned(player.curTokenBadgeId())) continue;
      alert("You can't place tokens to this region. You should place tokens on not adjacent regions");
      return;
    }
  }
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
  alert('Wrong action');
}

function commitStageDefend() {
  checkDeploy(
    cmdDefend,
    function(i, regions) {
      if (defend.regions[i] != 0) regions.push({ regionId: parseInt(i), tokensNum: defend.regions[i] })
    });
}

function commitStageBeforeConquest() {
  setGameStage(GS_CONQUEST);
}

function commitStageConquest() {
  player.beforeRedeploy();
  setGameStage(GS_REDEPLOY);
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
  //setGameStage(GS_FINISH_TURN);
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

function watchGame() {
  var gameId = $("input:radio[name=listGameId]").filter(":checked").val();
  setGame(gameId);
  showLobby();
}

function leaveWatch() {
  data.gameId = null;
  data.game = null;
  _setCookie(["gameId"], [null]);
  $("#tdLobbyChat").append($("#divChat").detach());
  showLobby();
}
