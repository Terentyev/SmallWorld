var regions = [];
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
  if (!$('#checkBoxDragon').is(':disabled') && $('#checkBoxDragon').is(':checked')) {
    areaClickAction = areaDragonAttack;
    if (!$('#checkBoxEnchant').is(':disabled'))
      $('#checkBoxEncant').attr('checked', false);
  }
  else
    areaClickAction = areaConquer;
}

function decline() {
  if (confirm('Do you really want to decline your race "' + player.curRace() + '"?')) {
    cmdDecline();
  }
}

function enchant() {
  if (!$('#checkBoxEnchant').is(':disabled') && $('#checkBoxEnchant').is(':checked')) {
    areaClickAction = areaEnchant;
    if (!$('#checkBoxDragon').is(':disabled'))
      $('#checkBoxDragon').attr('checked', false);
  }
  else
    areaClickAction = areaConquer;
}

function throwDice() {
  if (!player.tokens() || !player.canThrowDice()) {
    alert('You can\'t trow dice');
    return;
  }
  cmdThrowDice();
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
  showModal('#divAskNum', modalSize.minHeight + 2*modalSize.lineHeight, 350);
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
        case LE_DEFEND:
          gs.stage = player.tokens() == 0
            ? GS_REDEPLOY
            : GS_CONQUEST;
          break;
        case LE_THROW_DICE:
        case LE_CONQUER:
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
  mergeMember(gs, 'berserkDice',        [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'stage',              [showPlayers, changeGameStage], acts);
  mergeMember(gs, 'currentTurn',        [showGameTurn],                 acts);
  mergeMember(gs, 'visibleTokenBadges', [showBadges],                   acts);
  mergeMember(gs, 'map',                [showGameMap],                  acts);
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
  var r = regions[regionId];
  setGameStage(r.needDefend() ? GS_DEFEND: GS_CONQUEST);
  player.setRegionId(regionId);
  cmdConquer(regionId);
}

function areaDragonAttack(regionId) {
  if (!player.canDragonAttack(regionId)) {
    return;
    setGameStage(GS_CONQUEST);
  }
  var r = regions[regionId];
  setGameStage(r.needDefend() ? GS_DEFEND: GS_CONQUEST);
  player.setRegionId(regionId);
  //dragonAttack();
  cmdDragonAttack(regionId);
}

function areaEnchant(regionId) {
  if (!player.canEnchant(regionId)) {
    return;
    setGameStage(GS_CONQUEST);
  }
  var r = regions[regionId];
  setGameStage(r.needDefend() ? GS_DEFEND : GS_CONQUEST);
  player.setRegionId(regionId);
  cmdEnchant(regionId);
}

function areaPlaceTokens(regionId) {
  // TODO: do needed checks
  place = regions[regionId];
  if (!place.isOwned(player.curTokenBadgeId())) {
    alert('Wrong region');
    return;
  }
  var s = '';
  $('#spanRedeployObjectName').empty();
  $('#spanRedeployObject').empty();
  switch (player.curPower()) {
    case 'Bivouacking':
      var count = parseInt(place.get('encampment'));
      $('#spanRedeployObjectName').html('Encampments:');
      s = '<select id="selectEncampments">';
      for (var i = 0; i <= ENCAMPMENTS_MAX - player.getObjectCount('encampment') + count; ++i) {
        s += addOption(i, i, i == count);
      }
      s += '</select>';
      $(s).appendTo('#spanRedeployObject');
      break;
    case 'Fortified':
      $('#spanRedeployObjectName').html('Fortified:');
      $($.sprintf('<input type="checkbox" id="checkFortified" %s %s>',
        regions[regionId].get('fortified') ? 'checked="checked"': '',
        player.canPlaceObject(regionId, 'fortified') ? '': 'disabled="disabled"')).appendTo('#spanRedeployObject');
      break;
    case 'Heroic':
      $('#spanRedeployObjectName').html('Hero:');
      $($.sprintf('<input type="checkbox" id="checkHero" %s %s>',
        regions[regionId].get('hero') ? 'checked="checked"': '',
        player.canPlaceObject(regionId, 'fortified') ? '': 'disabled="disabled"')).appendTo('#spanRedeployObject');
  }

  askNumBox('How much tokens deploy on region?',
            deployRegion,
            place.tokens());
}

function deployRegion() {
  if (checkAskNumber()) return;
  var v = parseInt($("#inputAskNum").attr("value"));
  if (checkEnough(v - place.tokens() > player.tokens(), '#divAskNumError')) return;

  if (v > 0) {
    if ($('#checkFortified').length && !$('#checkFortified').is(':disabled')) {
      player.placeObject(place.regionId(), 'fortified', $('#checkFortified').is(':checked'));
    }
    if ($('#checkHero').length && !$('#checkHero').is(':disabled')) {
      player.placeObject(place.regionId(), 'hero', $('#checkHero').is(':checked'));
    }
    if ($('#selectEncampments').length) {
      player.placeObject(place.regionId(), 'encampment', parseInt($('#selectEncampments').val()));
    }
  } else
    player.removeObjects(place.regionId());
  player.addTokens(place.tokens() - v);
  place.rmTokens(place.tokens() - v);
  $.modal.close();
}

function areaDefend(regionId) {
  // TODO: do needed checks
  var region = regions[regionId];
  if (!region.isOwned(player.curTokenBadgeId())) {
    alert('Wrong region');
    return;
  }

  // TODO: check adjacent regions
  var loose = regions[data.game.defendingInfo.regionId];
  if (loose.isAdjacent(regionId)) {
    for (var i in regions) {
      //var cur = regions[i];
      if (loose.isAdjacent(i) || !regions[i].isOwned(player.curTokenBadgeId())) continue;
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
  regions[defend.regionId].setDefendTokenNum(v);
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
      if (defend.regions[i]) regions.push({ regionId: parseInt(i), tokensNum: defend.regions[i] })
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
    function(i, regs, camps, heroes) {
      var cur = regions[i];
      if (cur.tokens() != 0) regs.push({ regionId: parseInt(i), tokensNum: cur.tokens() });
      if (cur.get('hero')) heroes.push({ regionId: parseInt(i)});
      if (cur.get('encampment')) camps.push({ regionId: parseInt(i), encampmentsNum: parseInt(cur.get('encampment'))});
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
  var regs = null, camps = [], heroes = [];
  for (var i in regions) {
    if (!regions[i].isOwned(player.curTokenBadgeId())) continue;
    if (regs == null) {
      regs = [];
    }
    add(i, regs, camps, heroes);
  }

  if (regs == null) {
    cmdGetGameState();
  }
  else if (regs.length != 0) {
    if (player.curPower() == 'Heroic' && !heroes.length || (heroes.length == 1) && (regs.length != 1))
      alert('Place each of your two Heroes in regions you occupy');
    else
      cmd(regs, camps, heroes, player.getLastFortifiedRegion());
  }
  else {
    alert('You should place you tokens in the world');
  }
}

function watchGame() {
  if (data.gameId != null) return;
  var gameId = $("input:radio[name=listGameId]").filter(":checked").val();
  setGame(gameId, false);
  showLobby();
}

function leaveGame() {
  if (!confirm('Do you really want to leave game')) return;
  if (data.inGame) cmdLeaveGame();
  else {
    clearGame();
    showLobby();
  }
}
