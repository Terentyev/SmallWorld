function showModal(divName, h, w) {
  h = h || 160;
  w = w || 420;
  $(divName).modal({
    closeHTML: "<a href='#' title='Close' class='modal-close'>x</a>",
    position: ["10%"],
    closeClass: "modal-close",
    overlayId: "modal-overlay",
    containerId: "modal-container",
    containerCss: {height:h, width: w}
  });
}

function saveServerUrl() {
  serverUrl = $("#inputServerUrl").val();
  $("#serverUrl").html(serverUrl);
  _setCookie(["serverUrl"], [serverUrl]);
  showLobby();
};

function showSelectServer() {
  var s = (serverUrl != null ? serverUrl : "http://server.smallworld");
  $("#inputServerUrl").val(s);
  showModal("#divSelectServer", 110);
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
  if (data.game == null || data.game.state == GST_WAIT) return;

  $("#divGame").css("display", "block");
  $("#divLobby").css("display", "none");
  $("#tdGameChat").append($("#divChat").detach());

  showGameMap();
  showBadges();
  showPlayers();
  showGameStage();
}

function showGameMap() {
  if (data.game == null || data.game.state == GST_WAIT || maps[data.game.map.mapId] == null) {
    return;
  }

  if ($("#imgMap").attr("src") === maps[data.game.map.mapId].url) return;

  var img = new Image();
  img.onload = loadGameMapImg;
  img.src = serverUrl + maps[data.game.map.mapId].url;
  showRegions();
  showMapObjects();
}

function loadGameMapImg() {
  $('#imgMap').attr('src', this.src);
  $("#divMapObjects").css("width", this.width);
  $("#divMapObjects").css("top", - this.height);
  $("#divMapObjects").show();
}

function showBadges() {
  var s = '';
  for (var i in data.game.visibleTokenBadges) {
    var cur = data.game.visibleTokenBadges[i];
    s += addRow([$.sprintf(
          "<a href='#' class='clickable' onclick='tokenBadgeClick(%d)'>" +
          "<img src='%s' class='badge' />" +
          "<img src='%s' class='badge' /></a>",
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
  $('#spanGameStage').html(
      gameStages[data.game.stage][player.isActive()]);
  $('#spanGameStage').trigger('update');
  $('#placeDecline').html(
      (player.isActive() && data.game.stage == 'beforeConquest'
       ? $('#divDecline').html()
       : ''));
  $('#placeDecline').trigger('update');
}

function showLobby() {
  $("#divLobby").css("display", "block");
  $("#divGame").css("display", "none");
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

function showScores() {
  var s = '';
  for (var i in data.game.players) {
    with (data.game.players[i]) {
      s += addRow([username, coins]);
    }
  }
  $('#tableScores tbody').html(s);
  $('#tableScores tbody').trigger('update');
  showModal('#divScores');
}

function showTurnScores(stats) {
  var s = '', c = 0;
  for (var i in stats) {
    if (stats[i][1] == 0) continue;
    s += addRow([stats[i][0], stats[i][1]]);
    ++c;
  }
  if (s == '') {
    s = addRow(['Not coins for turn']);
    ++c;
  }
  $('#tableTurnScores tbody').html(s);
  $('#tableTurnScores tbody').trigger('update');
  showModal('#divTurnScores', 70+c*40, 300);
}

function changeMap(mapId) {
  $("#spanMaxTurns").html(maps[mapId].turns);
  $("#spanMaxPlayers").html(maps[mapId].players);
}
