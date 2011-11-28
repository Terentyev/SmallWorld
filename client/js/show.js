var gameStages = {
  null: [''],
  '': [''],
  'defend': ["Let's defend, my friend!", "Wait other players"],
  'selectRace': ["So... You should select your path... or race", "Wait other players"],
  'conquest': ["Do you want some fun? Let's conquer some regions", "Wait other players"],
  'redeploy': ["Place your warriors to the world", "Wait other players"],
  'finishTurn': ["Click finish-turn button, dude", "Wait other players"],
  'gameOver': ["Oops!.. Game over", "Oops!.. Game over"]
};


function showModal(divName) {
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
  $("#divCurrentGame").css("display", (data.gameId != null ? "block" : "none"));
}

function showGame() {
  if (data.game == null || !data.game.state) return;

  $("#divGame").css("display", "block");
  $("#divLobby").css("display", "none");
  $("#tdGameChat").append($("#divChat").detach());

  showGameMap();
  showBadges();
  showPlayers();
  showRegions();
  showMapObjects();
  showGameStage();
}

function showGameMap() {
  if ($("#imgMap").attr("src") === maps[data.game.map.mapId].url) return;

  $("#imgMap").attr("src", serverUrl + maps[data.game.map.mapId].url);
  $("#divMapObjects").css("width", document.getElementById("imgMap").clientWidth);
  $("#divMapObjects").css("top", - document.getElementById("imgMap").clientHeight);
}

function showBadges() {
  var s = '';
  for (var i in data.game.visibleTokenBadges) {
    var cur = data.game.visibleTokenBadges[i];
    s += addRow([$.sprintf(
          "<a href='#' class='clickable' onclick='tokenBadgeClick(%d)'>" +
          "<img src='%s' /><img src='%s' /></a>",
          i, races[cur.raceName], specialPowers[cur.specialPowerName])]);
  }
  $("#tableTokenBadges tbody").html(s);
  $("#tableTokenBadges").trigger("update");
}

function showPlayers() {
  var s = '';
  for (var i in data.game.players) {
    var cur = data.game.players[i];
    if (cur.userId == data.playerId) {
      s = addOurPlayerInfo(cur) + s;
    }
    else {
      s += addPlayerInfo(cur);
    }
  }
  $("#tablePlayers tbody").html(s);
  $("#tablePlayers").trigger("update");
}

function showMapObjects() {
  var s = '';
  for (var i in data.game.map.regions) {
    var cur = data.game.map.regions[i];
    s += addTokensToMap(cur, i) + addObjectsToMap(cur, i);
  }
  $("#divMapObjects").html(s);
  $("#divMapObjects").trigger("update");
}

function showRegions() {
  var s = '';
  for (var i in data.game.map.regions) {
    var cur = data.game.map.regions[i];
    s += addAreaPoly(maps[data.game.map.mapId].regions[i].coordinates, i);
  }
  $("#mapLayer").html(s);
  $("#mapLayer").trigger("update");
  $("#imgMap").maphilight();
}

function showGameStage() {
  $("#spanGameStage").html(gameStages[data.game.stage][data.game.activePlayerId == data.userId ? 0 : 1]);
  $("#spanGameStage").trigger("update");
}

function showLobby() {
  showLogin();
  showCurrentGame();
  cmdGetMessages();
  cmdGetGameList();
  if (data.playerId != null && data.gameId == null) {
    $("#tabs").tabs("enable", 1);
    $("#tabs").tabs("enable", 2);
  } else {
    $("#tabs").tabs("select", 0);
    $("#tabs").tabs("disable", 1);
    $("#tabs").tabs("disable", 2);
  }
}

function showMessages() {
  var api = $('#divMessages').data('jsp');
  var s = '';
  var cur;
  for (var i in messages) {
    cur = messages[i];
    s += $.sprintf('<p id="message%d"><b>%s:</b> %s</p>',cur.id, cur.username, cur.text);
  }
  api.getContentPane().html(s);
  api.reinitialise();
  api.scrollToBottom();
}

function changeMap(mapId) {
  $("#spanMaxTurns").html(maps[mapId].turns);
  $("#spanMaxPlayers").html(maps[mapId].players);
}
