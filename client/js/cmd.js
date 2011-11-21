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
  data.playerId = ans.playerId;
  data.sid = ans.sid;
  _setCookie(["playerId", "sid", "username"], [data.playerId, data.sid, data.username]);
  $("#divLoginError").empty();
  showLogin();
}

function cmdLogout() {
  var cmd = {
    action: "logout",
    sid: data.sid
  };
  sendRequest(cmd, hdlLogout);
}

function hdlLogout(ans) {
  //You have been logged out. Come back soon!
  with (data) {
    playerId = null;
    sid = null;
    username = null;
    gameId = null;
  }
  _setCookie(["playerId", "sid", "username", "gameId"], [null, null, null, null]);
  showLogin();
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
  var s = '';
  for (var i in ans.maps) {
    with(ans.maps[i]) {
      maps[mapId] = { "name": mapName, "turns": turnsNum, "players": playersNum };
      s += $.sprintf("<option value='%s'>%s</option>", mapId, mapName);
    }
  }
  $("#mapList").html(s);
  $("#mapList").change();
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
  showLobby();
}

function cmdGetGameList() {
  var cmd = {
    action: "getGameList"
  };
  sendRequest(cmd, hdlGetGameList);
}

function hdlGetGameList(ans) {
  var cur, s = '', notInGame = (data.gameId == null), makeCurrent = !notInGame;

  for (var i in ans.games) {
    cur = ans.games[i];
    games[cur.gameId] = {"name": cur.gameName, "description": cur.gameDescription, "mapId": cur.mapId,
                         "turnsNum": cur.turnsNum };

    s +=
    $.sprintf("<tr><td><input type='radio' name='listGameId' value='%s' /></td><td>%s</td><td>%d/%d</td><td>%d</td><td>%d/%d</td><td>%s</td></tr>",
    cur.gameId, cur.gameName, cur.players.length, cur.maxPlayersNum, cur.mapId, cur.turn, cur.turnsNum, cur.gameDescription);
    if (notInGame)
      for (var j in cur.players)
        if (cur.players[j].userId == data.playerId) {
          data.gameId = cur.gameId;
          notInGame = false;
          break;
        }
  }

  $("#tableGameList tbody").html(s);
  $("#tableGameList").trigger("update");
  $("input:radio[name=listGameId]").first().attr("checked", 1);
  //$("input:radio[name=listGameId]").attr("hidden", 1);
  /*var tmp = $("#tableGameList tr");
  tmp.click(function (){
    $("input:radio[name=listGameId]").eq(tmp.index(this)).attr("checked", 1);
  });*/
  /*var sorting = [[2,1],[0,0]];

  $("table").trigger("sorton",[sorting]);*/

  if (makeCurrent) {
    with (games[data.gameId]) {
       $("#cgameName").html(name);
       $("#cgameDescription").html(description);
       $("#cgameMap").html(mapId);
       $("#cgameTurnsNum").html(turnsNum);
    }
  }
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
