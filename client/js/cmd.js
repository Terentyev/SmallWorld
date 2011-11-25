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
    with(ans.maps[i]) {
      maps[mapId] = { "name": mapName, "turns": turnsNum, "players": playersNum };
      s += $.sprintf("<option value='%s'>%s</option>", mapId, mapName);
      sel = $("span._tmpMap_"+mapId);
      parent = sel.parent();
      sel.remove();
      parent.html(mapName);
    }
  }
  $("#mapList").html(s);
  $("#mapList").change();
  $("span.tmpmapcontent").remove()
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
  data.gameId = sentedGameId;
  _setCookie(["gameId"], [data.gameId]);
  makeCurrentGame(games[data.gameId]);
  showLobby();
}

function cmdGetGameList() {
  var cmd = {
    action: "getGameList"
  };
  sendRequest(cmd, hdlGetGameList);
}

function makeCurrentGame(game) {
  with (game) {
    $("#cgameName").html(name);
    $("#cgameDescription").html(description);
    $("#cgameMap").html(getMapName(mapId));
    $("#cgameTurnsNum").html(turnsNum);
  }
}

function updatePlayersInGame(gameId) {
  with (games[gameId]) {
    var s = $.sprintf("%d/%d", players.length, playersNum);
    s +="<br>";
    //alert(JSON.stringify(players));
    for (var i in players) {
      with (players[i]) {
        s += $.sprintf("%s %s<br>", userName, isReady ? "ready" : "");
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
  var cur, s = '', needLoadMaps = false;

  for (var i in ans.games) {
    cur = ans.games[i];
    games[cur.gameId] = {"name": cur.gameName, "description": cur.gameDescription, "mapId": cur.mapId,
                         "turnsNum": cur.turnsNum, "players": cur.players, "playersNum": cur.maxPlayersNum };
    if (!maps[cur.mapId]) needLoadMaps = true;
    if (data.gameId == null)
      for (var j in cur.players)
        if (cur.players[j].userId == data.playerId) {
          data.gameId = cur.gameId;
          break;
        }
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

  if (data.gameId != null) {
    if (needMakeCurrent) {
      alert("create from cmd" + data.gameId);
      //data.gameId = tmpGameId;
      makeCurrentGame(games[data.gameId]);
      needMakeCurrent = false;
    }
    $("input:radio[name=listGameId]").attr("hidden", 1);
    updatePlayersInGame(data.gameId);
    if (!maps[games[data.gameId].mapId]) needLoadMaps = true;
  }
  if (needLoadMaps) cmdGetMapList();
  showCurrentGame();
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
  cmdGetGameList();
}
