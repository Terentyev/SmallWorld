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
  data.game = null;
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
  showGameTurn();
  showGameMap();
  showBadges();
  showPlayers();
  showGameStage();
}

function showGameTurn(){
  var s = (data.game.state == GST_FINISH) ?
          'game is over': $.sprintf("%d from %d", data.game.currentTurn + 1, data.game.map.turnsNum);
  $("#spanGameTurn").html(s);
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

function showCoin(type, num, dx, dy, off){
  var s = '';
  for (var i = 0; i < num; ++i){
    s += $.sprintf('<img src="./pics/coin%d.png" class="coin" style="top:%d; left:%d" />',
                    type, off.y-4*i*dy, off.x-4*i*dx);
  }
  off.x -= 4*num*dx;
  off.y -= 4*num*dy;
  return s;
}

function showCoins(num, dx, dy) {
  dx = dx == null ? 1 : dx;
  dy = dy == null ? 0 : dy;
  if (num <= 0) return '';
  var w = 16+(num-1)*4*dx, h = 16+(num-1)*4*dy;
  var s = $.sprintf('<div class="coin-container" style="width:%d; height:%d" title="%s">', w, h, num);
  var a = Math.floor(num / 25), b = Math.floor((num - a*25)/5);
  num = num - a*25 - b*5;
  var off = { x: 4*(num + a + b -1)*dx, y : 4*(num + a + b -1)*dy };
  s += showCoin(1, num, dx, dy, off);
  s += showCoin(5, b, dx, dy, off);
  s += showCoin(25, a, dx, dy, off);
  s += '</div>';
  return s;
}

function showBadges() {
  var s = '';
  for (var i in data.game.visibleTokenBadges) {
    var cur = data.game.visibleTokenBadges[i];
    s += addRow([showCoins(cur.bonusMoney, 0, 1), $.sprintf(
          "<a href='#' class='clickable' onclick='tokenBadgeClick(%d)'>" +
          "<img src='%s' class='badge' title=\"%s\"/>" +
          "<img src='%s' class='badge' /></a>",
          i, getRaceImage(cur.raceName, 'race'), raceDescription[cur.raceName], specialPowers[cur.specialPowerName])]);
  }
  $("#tableTokenBadges tbody").html(s);
  $("#tableTokenBadges").trigger("update");
}

function showPlayers() {
  var s = '';
  for (var i in data.game.players) {
    var cur = data.game.players[i];
    if (cur.userId == data.playerId) $("#tableCurrentPlayer tbody").html(addOurPlayerInfo(cur));
    s += addPlayerInfo(cur);
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
  var s = '', sum = 0;
  var p = [];
  for (var i in data.game.players)
    p.push( {'username': data.game.players[i].username, 'coins': data.game.players[i].coins});
  p.sort(function(a, b){ return b.coins - a.coins});
  for (var i in p)
    s += addRow([(parseInt(i)+1)+'.', p[i].username, showCoins(p[i].coins, 1, 0)]);
  $('#tableScores tbody').html(s);
  $('#tableScores tbody').trigger('update');
  showModal('#divScores', 110+p.length*28, 300);
}

function showTurnScores(stats) {
  var s = '', c = 0, sum = 0;
  for (var i in stats) {
    if (stats[i][1] == 0) continue;
    s += addRow([stats[i][0]+":", showCoins(stats[i][1], 1, 0)]);
    sum += stats[i][1];
    ++c;
  }
  if (!sum) {
    s = '<tr><td colspan="2">Not coins for turn</td></tr>';
    ++c;
  }
  $('#tableTurnScores tbody').html(s);
  showModal('#divTurnScores', 110+c*28, 250);
}

function changeMap(mapId) {
  $("#spanMaxTurns").html(maps[mapId].turns);
  $("#spanMaxPlayers").html(maps[mapId].players);
  var s = '';
  for (var i = 0; i <= maps[mapId].players; ++i) {
    s += addOption(i, i);
  }
  $("#selectAINum").html(s);
}

function test() {
}
