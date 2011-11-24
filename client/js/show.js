﻿function showModal(divName) {
  $(divName).modal({
    closeHTML: "<a href='#' title='Close' class='modal-close'>x</a>",
    position: ["10%"],
    closeClass: "modal-close",
    overlayId: "modal-overlay",
    containerId: "modal-container",
  });
}

function saveServerUrl() {
  serverUrl = $("#inputServerUrl").val();
  $("#serverUrl").html(serverUrl);
  _setCookie(["serverUrl"], [serverUrl]);
  showLobby();
};

function showSelectServer() {
  var s = (serverUrl != null ? serverUrl : "is not defined");
  $("#serverUrlModal").val(s);
  showModal("#divSelectServer");
}

function showLogin() {
  if (data.playerId != null) {
    $("#playerName").html(data.username);
    $("#divLogin").css("display", "none");
    $("#divLogout").css("display", "block");
  } else {
    $("#divLogin").css("display", "block");
    $("#divLogout").css("display", "none");
  }
}

function showCurrentGame() {
  if (data.gameId != null) {
    $("#divCurrentGame").css("display", "block");
  } else {
    $("#divCurrentGame").css("display", "none");
  }
}

function showLobby() {
  showLogin();
  showCurrentGame();
  cmdGetMapList();
  cmdGetMessages();
  cmdGetGameList();
  if (data.playerId != null && data.gameId == null) {
    $("#tabs").tabs("enable", 1);
    $("#tabs").tabs("enable", 2);
    $("#tabs").tabs("enable", 4);
  } else {
    $("#tabs").tabs("select", 0);
    $("#tabs").tabs("disable", 1);
    $("#tabs").tabs("disable", 2);
    $("#tabs").tabs("disable", 4);
  }
}

function showMessages() {
  var api = $('#divMessages').data('jsp');
  var s = '';
  var cur;
  for (var i in messages) {
    cur = messages[i];
    s += $.sprintf('<p id="message%d"><b>%s:</b> %s</p>',cur.id, cur.userName, cur.text);
  }
  api.getContentPane().html(s);
  api.reinitialise();
  api.scrollToBottom();
}

function changeMap(mapId) {
  $("#spanMaxTurns").html(maps[mapId].turns);
  $("#spanMaxPlayers").html(maps[mapId].players);
}
