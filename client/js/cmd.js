function cmdRegister() {
  var name = $('#inputRegisterUsername').val(), pass = $('#inputRegisterPassword').val();
  if (!checkUsernameAndPassowrd(name, pass, '#divRegisterError')) return;
  var cmd = {
    action: 'register',
    username: name,
    password: pass
  };
  sendRequest(cmd, hdlRegister, '#divRegisterError');
}

function hdlRegister(ans) {
  $('#inputLoginUsername').val($('#inputRegisterUsername').val());
  $('#inputLoginPassword').val($('#inputRegisterPassword').val());
  $.modal.close();
  $('#divRegisterError').empty();
  cmdLogin();
}

function cmdLogin() {
  data.username = $('#inputLoginUsername').val();
  var cmd = {
    action: 'login',
    username: data.username,
    password: $('#inputLoginPassword').val()
  };
  sendRequest(cmd, hdlLogin, '#divLoginError');
}

function hdlLogin(ans) {
  //'Login accepted. Welcome back, '+ data.username
  data.playerId = ans.userId;
  data.sid = ans.sid;
  _setCookie(['playerId', 'sid', 'username'], [data.playerId, data.sid, data.username]);
  $('#divLoginError').empty();
  showLobby();
}

function cmdLogout() {
  var cmd = {
    action: 'logout',
    sid: data.sid
  };
  with (data) {
    playerId = null;
    sid = null;
    username = null;
    gameId = null;
  }
  _setCookie(['playerId', 'sid', 'username', 'gameId', 'inGame'], [null, null, null, null, null]);
  showLobby();
  sendRequest(cmd, null);
}

function cmdSendMessage() {
  var cmd = {
    action: 'sendMessage',
    sid: data.sid,
    text: $('#inputMessageText').val()
  };
  sendRequest(cmd, hdlSendMessage);
}

function hdlSendMessage(ans) {
  $('#inputMessageText').val('');
  cmdGetMessages();
}

function cmdGetMessages() {
  var cmd = {
    action: 'getMessages',
    since: messages.length? messages[messages.length - 1].id : 0
  };
  sendRequest(cmd, hdlGetMessages);
}

function hdlGetMessages(ans) {
  var cur;
  for (var i in ans.messages)
    messages.push(ans.messages[i]);
  while (messages.length > maxMessagesCount)
    messages.shift();
  showMessages();
}

function cmdGetMapList() {
  var cmd = {
    action: 'getMapList'
  };
  sendRequest(cmd, hdlGetMapList);
}

function hdlGetMapList(ans) {
  var s = '', sel = null;
  for (var i in ans.maps) {
    var regs = new Array();
    for (var j in ans.maps[i].regions) {
      regs[parseInt(j) + 1] = ans.maps[i].regions[j];
    }
    with(ans.maps[i]) {
      maps[mapId] = {
        'name': mapName,
        'turns': turnsNum,
        'players': playersNum,
        'url': picture,
        'regions': regs
      };
      s += addOption(mapId, mapName);
      sel = $('span._tmpMap_'+mapId);
      parent = sel.parent();
      sel.remove();
      parent.html(mapName);
    }
  }
  $('#mapList').html(s);
  $('#mapList').change();
  $('span.tmpmapcontent').remove();
  showGameMap();
}

function cmdCreateGame() {
  var cmd = {
    action: 'createGame',
    gameName: $('#inputGameName').val(),
    mapId: $('#mapList').val() * 1,
    gameDescription: $('#inputGameDescr').val(),
    ai: $('#selectAINum').val() * 1,
    sid: data.sid
  };
  sendRequest(cmd, hdlCreateGame);
}

function hdlCreateGame(ans) {
  if ( $('#selectAINum').val() < maps[$('#mapList').val()].players ) {
    data.gameId = ans.gameId;
    _setCookie(['gameId'], [data.gameId]);
    makeCurrentGame({
      name: $('#inputGameName').val(),
      description: $('#inputGameDescr').val(),
      mapId: $('#mapList').val() * 1,
      turnsNum: maps[$('#mapList').val()].turnsNum
    });
  }
  showLobby();
}

function cmdJoinGame() {
  sentedGameId = $('input:radio[name=listGameId]').filter(':checked').val();
  if (sentedGameId == null) {
    showError('Game not selected');
    return;
  }
  var cmd = {
    action: 'joinGame',
    gameId: sentedGameId * 1,
    sid: data.sid
  };
  sendRequest(cmd, hdlJoinGame);
}

function hdlJoinGame(ans) {
  setGame(sentedGameId, true);
  showLobby();
}

function cmdGetGameList() {
  var cmd = {
    action: 'getGameList'
  };
  sendRequest(cmd, hdlGetGameList);
}

function updatePlayersInGame() {
  with (data.game) {
    var s = $.sprintf('%d/%d', currentPlayersNum, map.playersNum);
    s += '<br>';
    $('#checkBoxReady').attr('disabled', !data.inGame ? 'disabled': null).attr('checked', null);
    for (var i in players) {
      with (players[i]) {
        s += $.sprintf('%s %s<br>', username, isReady ? 'ready' : '');
        if (userId == data.playerId && isReady)
          $('#checkBoxReady').attr('checked', 'checked');
      }
    }
    $('#cgamePlayers').html(s);
  }
}

function hdlGetGameList(ans) {
  var cur, s = '', needLoadMaps = false, gameStarted = false, cursor = '', inGameCount = 0, inGame = false;
  needLoadMaps = needLoadMaps || !ans.length;
  for (var i in ans.games) {
    cur = ans.games[i];
    needLoadMaps = needLoadMaps || !maps[cur.mapId];

    var players = new Array();
    inGameCount = 0;
    for (var j in cur.players) {
      players[cur.players[j].userId] = cur.players[j];
      if (cur.players[j].inGame) {
        ++inGameCount;
        if (cur.players[j].userId == data.playerId) {
          //мы в игре но браузер не в курсе
          if (data.gameId == null) data.gameId = cur.gameId;
          inGame = true;
        }
      }
    }
    games[cur.gameId] = {"name": cur.gameName, "description": cur.gameDescription, "mapId": cur.mapId,
                         "turnsNum": cur.turnsNum, "players": players, "playersNum": cur.maxPlayersNum,
                         "inGame": cur.state != GST_WAIT};

    gameStarted = gameStarted || (games[cur.gameId].inGame && data.gameId == cur.gameId);

    cursor = data.gameId != cur.gameId ?
             $.sprintf("<input type='radio' name='listGameId' value='%s'/>", cur.gameId) :
             '<img src="/pics/currentPlayerCursor.png" />';
    s += addRow([cursor,
                cur.gameName,
                $.sprintf("%d/%d", inGameCount, cur.maxPlayersNum),
                getMapName(cur.mapId),
                cur.state == GST_WAIT ? 'Not started' :$.sprintf("%d/%d", cur.turn, cur.turnsNum),
                $.sprintf("<div class='wrap'>%s</div>", cur.gameDescription)]);
  }

  $('#tableGameList tbody').html(s);
  $('input:radio[name=listGameId]').first().attr('checked', 1);
  var tmp = $('#tableGameList tbody tr');
  tmp.mouseover(function() {$(this).addClass('hover'); })
     .mouseout(function() {$(this).removeClass('hover'); })
     .click(function (){
       $('input:radio[name=listGameId]').eq(tmp.index(this)).attr('checked', 1);
     });
  if (data.gameId != null) {
    $('input:radio[name=listGameId]').attr('hidden', 1);
    $('#btnJoin').hide();
    $('#btnWatch').hide();
    setGame(data.gameId, inGame);
  } else {
    $('#btnJoin').show();
    $('#btnWatch').show();
  }
  if (needLoadMaps) cmdGetMapList();
}

function cmdLeaveGame() {
  var cmd = {
    action: 'leaveGame',
    sid: data.sid
  };
  sendRequest(cmd, hdlLeaveGame);
}

function hdlLeaveGame(ans) {
  clearGame();
  showLobby();
}

function cmdUploadMap() {
  var tmp;
  try {
    tmp = JSON.parse($('#inputMapRegions').val());
  } catch(err) {
    showError('Bad regions description');
    return;
  }
  var cmd = {
    action: 'uploadMap',
    mapName: $('#inputMapName').val(),
    playersNum: $('#mapPlayersNum').val(),
    turnsNum: $('#mapTurnsNum').val(),
    regions: tmp
  };
  sendRequest(cmd, hdlUploadMap);
}

function hdlUploadMap(ans) {
  uploadMap(ans.mapId);
  cmdGetMapList();
}

function cmdSetReady() {
  var cmd = {
    action: 'setReadinessStatus',
    sid: data.sid,
    isReady: $('#checkBoxReady').is(':checked') ? 1 : 0
  };
  sendRequest(cmd, hdlSetReady, '', errSetReady);
}

function hdlSetReady(ans) {
  cmdGetGameState();
}

function errSetReady(ans) {
  $('#checkBoxReady').attr('checked', null);
  showError(getErrorText(ans.result), null);
}

function cmdGetGameState() {
  var cmd = {
    action: 'getGameState',
    gameId: data.gameId * 1
  };
  sendRequest(cmd, hdlGetGameState, '#divGameError');
}

function hdlGetGameState(ans) {
  $('#divGameError').empty();
  var gs = ans.gameState;
  if (gs.state == GST_EMPTY) {
    clearGame();
    showLobby();
    return;
  }

  var gameStarted = (data.game == null || data.game.state == GST_WAIT) && gs.state != GST_WAIT;
  var regions = new Array();
  for (var i in gs.map.regions) {
    regions[parseInt(i) + 1] = gs.map.regions[i];
  }
  gs.map.regions = regions;
  mergeGameState(gs);
  if (data.game.state == GST_WAIT) {
    updatePlayersInGame();
  }
  //if (gameStarted) alert('In game');
}

/*******************************************************************************
   *         Token badge actions                                               *
   ****************************************************************************/
function cmdSelectRace(position) {
  var cmd = {
    action: 'selectRace',
    sid: data.sid,
    position: position
  };
  sendRequest(cmd, hdlSelectRace, '#divGameError');
}

function hdlSelectRace(ans) {
  cmdGetGameState();
}

/*******************************************************************************
   *         Area actions                                                      *
   ****************************************************************************/
function cmdConquer(regionId) {
  var cmd = {
    action: 'conquer',
    regionId: regionId * 1,
    sid: data.sid
  };
  sendRequest(cmd, hdlConquer, '#divGameError', errConquer);
}

function hdlConquer(ans) {
  // first implementation
  // TODO: change game state handly
  if (ans.dice != null) {
    alert($.sprintf(
          'Dice: %d.\n' +
          'Conquest is over.',
          ans.dice));
  }
  //regions[player.getRegionId()].conquerByPlayer(player, ans.dice);
  cmdGetGameState();
}

function errConquer(ans, cnt) {
  var et = getErrorText(ans.result);
  if (ans.dice == null) {
    showError(et, cnt);
    return;
  }

  alert($.sprintf(
        'Dice: %d\n' +
        'Not enough lucky.\n' +
        'Conquest is over.',
        ans.dice,
        et));
  commitStageConquest();
}

function cmdDefend(regions) {
  var cmd = {
    action: 'defend',
    regions: regions,
    sid: data.sid
  };
  sendRequest(cmd, hdlDefend, '#divGameError');
}

function hdlDefend(ans) {
  // first implementation
  // TODO: change game state handly
  cmdGetGameState();
}

function cmdRedeploy(regions, camps, heroes, fortressId) {
  var cmd = {
    action: 'redeploy',
    regions: regions,
    sid: data.sid
  };
  if (camps && camps.length) cmd.encampments = camps;
  if (heroes && heroes.length) cmd.heroes = heroes;
  if (fortressId) cmd.fortified = {'regionId': fortressId};

  sendRequest(cmd, hdlRedeploy, '#divGameError');
}

function hdlRedeploy(ans) {
  // first implementation
  // TODO: change game state handly
  cmdGetGameState();
}

/*******************************************************************************
   *         Finish turn actions                                               *
   ****************************************************************************/
function cmdFinishTurn() {
  var cmd = {
    action: 'finishTurn',
    sid: data.sid
  };
  sendRequest(cmd, hdlFinishTurn, '#divGameError');
}

function hdlFinishTurn(ans) {
  // first implementation
  // TODO: change game state handly
  cmdGetGameState();
  showTurnScores(ans.statistics);
}

/*******************************************************************************
   *         Decline actions                                                   *
   ****************************************************************************/
function cmdDecline() {
  var cmd = {
    action: 'decline',
    sid: data.sid
  };
  sendRequest(cmd, hdlDecline, '#divGameError');
}

function hdlDecline(ans) {
  // first implementation
  // TODO: change game state handly
  cmdGetGameState();
}

/*******************************************************************************
   *         Special powers commands                                           *
   ****************************************************************************/
function cmdThrowDice() {
  var cmd = {
    action: 'throwDice',
    sid: data.sid
  };
  sendRequest(cmd, hdlThrowDice, '#divGameError');
}

function hdlThrowDice(ans) {
  player.setBerserkDice(ans.dice);
  showGameStage();
}

function cmdSelectFriend(fid) {
  var cmd = {
    action: 'selectFriend',
    sid: data.sid,
    friendId: fid * 1
  };
  sendRequest(cmd, hdlSelectFriend);
}

function hdlSelectFriend(ans) {
  player.setSelectFriend();
  setGameStage(GS_FINISH_TURN);
  cmdGetGameState();
}

function cmdDragonAttack(regionId) {
  var cmd = {
    action: 'dragonAttack',
    sid: data.sid,
    regionId: regionId * 1
  };
  sendRequest(cmd, hdlDragonAttack, '#divGameError');
}

function hdlDragonAttack(ans) {
  player.setDragonAttack();
  showPlayers();
  // TODO: надо бы запомнить регион и обновлять вручную
  cmdGetGameState();
}

function cmdEnchant(regionId) {
  var cmd = {
    action: "enchant",
    sid: data.sid,
    regionId: regionId * 1
  };
  sendRequest(cmd, hdlEnchant, '#divGameError');
}

function hdlEnchant(ans) {
  player.setEnchant();
  showPlayers();
  // TODO: надо бы запомнить регион и обновлять вручную
  cmdGetGameState();
}
