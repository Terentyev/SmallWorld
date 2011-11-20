function cmdRegister() {
  var cmd = {
    action: "register",
    username: $("#inputRegisterUsername").val(),
    password: $("#inputRegisterPassword").val()
  };
  sendRequest(cmd, hdlRegister);
}

function hdlRegister(ans) {
  if (ans.result == 'ok') {
    $("#inputLoginUsername").val($("#inputRegisterUsername").val());
    $("#inputLoginPassword").val($("#inputRegisterPassword").val());
    $.modal.close();
    cmdLogin();
  } else
    $("#divRegisterError").html(cmdErrors[ans.result]+ans.result);
}

function cmdLogin() {
  data.username = $("#inputLoginUsername").val();
  var cmd = {
    action: "login",
    username: data.username,
    password: $("#inputLoginPassword").val()
  };
  sendRequest(cmd, hdlLogin);
}

function hdlLogin(ans) {
  var err = cmdErrors[ans.result];
  if (ans.result == 'ok') {
    //"Login accepted. Welcome back, "+ data.username
    data.playerId = ans.playerId;
    data.sid = ans.sid;
    _setCookie(["playerId", "sid", "username"], [data.playerId, data.sid, data.username]);
    showLogin();
  }
}

function cmdLogout() {
  var cmd = {
    action: "logout",
    sid: data.sid
  };
  sendRequest(cmd, hdlLogout);
}

function hdlLogout(ans) {
  if (ans.result == 'ok') {
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
  if (ans.result == 'ok')
    cmdGetMessages();
}

function cmdGetMessages() {
  var cmd = {
    action: "getMessages",
    since: messages.length? messages[messages.length-1].id : 0
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

function cmdCreateGame() {
  var cmd = {
    action: "createGame",
    gameName: $("#inputGameName").val(),
    mapId: $("#inputMapId").val(),
    gameDescr: $("#inputGameDescr").val(),
    sid: data.sid
  };
  sendRequest(cmd, hdlCreateGame);
}

function hdlCreateGame(ans) {
  if (ans.result == 'ok') {
    data.gameId = ans.gameId;
    _setCookie(["gameId"], [data.gameId]);
    showLobby();
  }
}

function cmdGetGameList() {
  var cmd = {
    action: "getGameList"
  };
  sendRequest(cmd, hdlGetGameList);
}

function hdlGetGameList(ans) {
  if (ans.result == 'ok') {
    var cur, s = '';
    var notInGame = (data.gameId == null), makeCurrent = !notInGame;

    for (var i in ans.games) {
      cur = ans.games[i];
      games[cur.gameId] = {"name": cur.gameName, "description": cur.gameDescription, "mapId": cur.mapId,
                           "turnsNum": cur.turnsNum };
      s += $.sprintf("<tr><td></td><td>%s</td><td>%d/%d</td><td>%d</td><td>%d/%d</td><td>%s</td></tr>",
      cur.gameName, cur.players.length, cur.maxPlayersNum, cur.mapId, cur.turn, cur.turnsNum, cur.gameDescription);
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
}

function cmdLeaveGame() {
  var cmd = {
    action: "leaveGame",
    sid: data.sid
  };
  sendRequest(cmd, hdlLeaveGame);
}

function hdlLeaveGame(ans) {
  if (ans.result == 'ok') {
    data.gameId = null;
    _setCookie(["gameId"], [null]);
    showLobby();
  }
}