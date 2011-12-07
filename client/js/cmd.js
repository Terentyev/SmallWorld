function cmdRegister() {
  var cmd = {
    action: "register",
    username: $("#inputRegisterUsername").val(),
    password: $("#inputRegisterPassword").val()
  };
  sendRequest(cmd, hdlRegister, '#divRegisterError');
}

function hdlRegister(ans) {
  $("#inputLoginUsername").val($("#inputRegisterUsername").val());
  $("#inputLoginPassword").val($("#inputRegisterPassword").val());
  $.modal.close();
  $("#divRegisterError").empty();
  cmdLogin();
}

function cmdLogin() {
  data.username = $("#inputLoginUsername").val();
  var cmd = {
    action: "login",
    username: data.username,
    password: $("#inputLoginPassword").val()
  };
  sendRequest(cmd, hdlLogin, '#divLoginError');
}

function hdlLogin(ans) {
  //"Login accepted. Welcome back, "+ data.username
  data.playerId = ans.userId;
  data.sid = ans.sid;
  _setCookie(["playerId", "sid", "username"], [data.playerId, data.sid, data.username]);
  $("#divLoginError").empty();
  showLobby();
}

function cmdLogout() {
  var cmd = {
    action: "logout",
    sid: data.sid
  };
  with (data) {
    playerId = null;
    sid = null;
    username = null;
    gameId = null;
  }
  _setCookie(["playerId", "sid", "username", "gameId"], [null, null, null, null]);
  showLobby();
  sendRequest(cmd, null);
}

function cmdSendMessage() {
  var cmd = {
    action: "sendMessage",
    sid: data.sid,
    text: $("#inputMessageText").val()
  };
  sendRequest(cmd, hdlSendMessage);
}

function hdlSendMessage(ans) {
  $("#inputMessageText").val('');
  cmdGetMessages();
}

function cmdGetMessages() {
  var cmd = {
    action: "getMessages",
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
    action: "getMapList"
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
        "name": mapName,
        "turns": turnsNum,
        "players": playersNum,
        "url": url,
        "regions": regs
      };
      s += $.sprintf("<option value='%s'>%s</option>", mapId, mapName);
      sel = $("span._tmpMap_"+mapId);
      parent = sel.parent();
      sel.remove();
      parent.html(mapName);
    }
  }
  $("#mapList").html(s);
  $("#mapList").change();
  $("span.tmpmapcontent").remove();
  showGameMap();
}

function cmdCreateGame() {
  var cmd = {
    action: "createGame",
    gameName: $("#inputGameName").val(),
    mapId: $("#mapList").val(),
    gameDescr: $("#inputGameDescr").val(),
    sid: data.sid
  };
  sendRequest(cmd, hdlCreateGame);
}

function hdlCreateGame(ans) {
  data.gameId = ans.gameId;
  _setCookie(["gameId"], [data.gameId]);
  makeCurrentGame({
    name: $("#inputGameName").val(),
    description: $("#inputGameDescr").val(),
    mapId: $("#mapList").val(),
    turnsNum: maps[$("#mapList").val()].turnsNum
  });
  showLobby();
}

function cmdJoinGame() {
  sentedGameId = $("input:radio[name=listGameId]").filter(":checked").val();
  if (sentedGameId == null) {
    showError('Game not selected');
    return;
  }
  var cmd = {
    action: "joinGame",
    gameId: sentedGameId,
    sid: data.sid
  };
  sendRequest(cmd, hdlJoinGame);
}

function hdlJoinGame(ans) {
  setGame(sentedGameId);
  showLobby();
}

function cmdGetGameList() {
  var cmd = {
    action: "getGameList"
  };
  sendRequest(cmd, hdlGetGameList);
}

function updatePlayersInGame() {
  with (data.game) {
    var s = $.sprintf("%d/%d", currentPlayersNum, map.playersNum);
    s +="<br>";
    //alert(JSON.stringify(players));
    for (var i in players) {
      with (players[i]) {
        s += $.sprintf("%s %s<br>", username, isReady ? "ready" : "");
        if (userId == data.playerId) {
          $('#checkBoxReady').attr('checked', isReady ? "checked": null)
          $('#readinessStatus').html(isReady ? "ready" : "not ready");
        }
      }
    }
    $("#cgamePlayers").html(s);
  }
}

function hdlGetGameList(ans) {
  var cur, s = '', needLoadMaps = false, gameStarted = false, gameId = null;

  for (var i in ans.games) {
    cur = ans.games[i];
    var players = new Array();
    for (var j in cur.players) {
      players[cur.players[j].userId] = cur.players[j];
    }
    games[cur.gameId] = {"name": cur.gameName, "description": cur.gameDescription, "mapId": cur.mapId,
                         "turnsNum": cur.turnsNum, "players": players, "playersNum": cur.maxPlayersNum,
                         "inGame": cur.state == 2};
    needLoadMaps = needLoadMaps || !maps[cur.mapId];
    if (gameId == null)
      for (var j in cur.players)
        if (cur.players[j].userId == data.playerId) {
          gameId = cur.gameId;
          break;
        }
    gameStarted = gameStarted || (cur.state == 2 && data.gameId == cur.gameId);
    s += addRow([$.sprintf("<input type='radio' name='listGameId' value='%s'/>", cur.gameId),
                cur.gameName,
                $.sprintf("%d/%d", cur.players.length, cur.maxPlayersNum),
                getMapName(cur.mapId),
                $.sprintf("%d/%d", cur.turn, cur.turnsNum),
                $.sprintf("<div class='wrap' width='100'>%s</div>", cur.gameDescription)]);
  }

  $("#tableGameList tbody").html(s);
  $("#tableGameList").trigger("update");
  $("input:radio[name=listGameId]").first().attr("checked", 1);
  var tmp = $("#tableGameList tbody tr");
  tmp.mouseover(function() {$(this).addClass("hover"); })
     .mouseout(function() {$(this).removeClass("hover"); })
     .click(function (){
       $("input:radio[name=listGameId]").eq(tmp.index(this)).attr("checked", 1);
     });

  if (gameId != null) {
    $("input:radio[name=listGameId]").attr("hidden", 1);
    setGame(gameId);
  }
  if (needLoadMaps) cmdGetMapList();
}

function cmdLeaveGame() {
  var cmd = {
    action: "leaveGame",
    sid: data.sid
  };
  sendRequest(cmd, hdlLeaveGame);
}

function hdlLeaveGame(ans) {
  data.gameId = null;
  _setCookie(["gameId"], [null]);
  showLobby();
}

function cmdUploadMap() {
  var tmp;
  try {
    tmp = JSON.parse($("#inputMapRegions").val());
  } catch(err) {
    showError('Bad regions description');
    return;
  }
  var cmd = {
    action: "uploadMap",
    mapName: $("#inputMapName").val(),
    playersNum: $("#mapPlayersNum").val(),
    turnsNum: $("#mapTurnsNum").val(),
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
  sendRequest(cmd, hdlSetReady);
}

function hdlSetReady(ans) {
  cmdGetGameState();
}

function cmdGetGameState() {
  var cmd = {
    action: "getGameState",
    sid: data.sid
  };
  sendRequest(cmd, hdlGetGameState);
}

function hdlGetGameState(ans) {
  var gs = ans.gameState;
  var gameStarted = (data.game == null || data.game.state != 1) && gs.state == 1;
  var regions = new Array();
  for (var i in gs.map.regions) {
    regions[parseInt(i) + 1] = gs.map.regions[i];
  }
  gs.map.regions = regions;
  mergeGameState(gs);
  if (data.game.state != 2) {
    updatePlayersInGame();
  }
  if (gameStarted) alert('Started');
}

/*******************************************************************************
   *         Token badge actions                                               *
   ****************************************************************************/
function cmdSelectRace(position) {
  var cmd = {
    action: "selectRace",
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
    action: "conquer",
    regionId: regionId,
    sid: data.sid
  };
  sendRequest(cmd, hdlConquer, '#divGameError');
}

function hdlConquer(ans) {
  // first implementation
  // TODO: change game state handly
  cmdGetGameState();
}

function cmdDefend(regions) {
  var cmd = {
    action: "defend",
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

function cmdRedeploy(regions) {
  var cmd = {
    action: "redeploy",
    regions: regions,
    sid: data.sid
  };
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
    action: "finishTurn",
    sid: data.sid
  };
  sendRequest(cmd, hdlFinishTurn, '#divGameError');
}

function hdlFinishTurn(ans) {
  // first implementation
  // TODO: change game state handly
  cmdGetGameState();
}

/*******************************************************************************
   *         Decline actions                                                   *
   ****************************************************************************/
function cmdDecline() {
  var cmd = {
    action: "decline",
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
    action: "throwDice",
    sid: data.sid
  };
  sendRequest(cmd, hdlThrowDice, '#divGameError');
}

function hdlThrowDice(ans) {
  player.setBerserkDice(ans.dice);
  showPlayers();
}
