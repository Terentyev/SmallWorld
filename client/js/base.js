var serverUrl = null;

messages = new Array();
maps = new Array();
games = new Array();

maxMessagesCount = 5, sentedGameId = null;
var data = {
      playerId: null,
      username: null,
      gameId: null,
      mapId: null,
      sid: 0
    };
var canvas = null;
var needMakeCurrent = false;

function getErrorText(errorCode) {
  return cmdErrors[errorCode] != null
    ? cmdErrors[errorCode]
    : errorCode;
}

function showError(errorText, container) {
  if (container)
    $(container).html(errorText);
  else
    alert(errorText);
}

function sendRequest(query, callback, errorContainer, errorCallback) {
  $.ajax({
    type: "POST",
    url: "http://client.smallworld",
    dataType: "JSON",
    timeout: 10000,
    data: {request: JSON.stringify(query), address: serverUrl},
    beforeSend: function() {
      $.blockUI({ message: '<h3><img src="./pics/loading.gif" /> Loading...</h3>' });
    },
    success: function(response) {
      if (!response || !response.result)
        showError("Unknown server response: " + JSON.stringify(response));
      else if (response.result == 'ok') {
        if (callback)
          callback(response);
      }
      else if (errorCallback)
        errorCallback(response, errorContainer)
      else
        showError(getErrorText(response.result), errorContainer);
      $.unblockUI();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      $.unblockUI();
      alert(textStatus);
    }
  });
}

function uploadMap(id) {
  $.ajaxFileUpload ({
    url:"http://client.smallworld/upload_map",
    secureuri:false,
    fileElementId: 'fileToUpload',
    data: {mapId: id, address: "http://server.smallworld/upload_map"},
    dataType: 'json',
    success: function (data, status) {
      if(typeof(data.error) != 'undefined') {
        alert(data);
        if (data.error != '') {
          alert(data.error);
        } else {
          alert(data.msg);
        }
      }
    },
    error: function (data, status, e) {
      alert(e);
    }
 });
}

function init() {
  $("#tabs").tabs();
  $("#tableGameList").tablesorter({headers: { 0: { sorter: false } } });
  $('.scroll-pane').jScrollPane({showArrows:true, scrollbarOnLeft: true});
  $('#mapList').change(function () {
    changeMap($(this).val());
  });
}

function _setCookie(key, value) {
  for (var i in key) $.cookie(key[i], value[i]);
}

function addRow(list) {
  var s = '<tr>';
  for (var i in list)
    s += $.sprintf('<td>%s</td>', list[i]);
  s += '</tr>'
  return s;
}

function addOption(value, string) {
  return $.sprintf('<option value="%s">%s</option>', value, string);
}

function getRaceImage(raceName, type, decline) {
  var name = 'None', prefix = './pics/', ext = '.png', postfix = decline ? '_decline': '';
  for (var i in races)
    if (raceName == races[i]) name = raceName;
  return prefix + type + name + postfix + ext;
}

function addPlayerInfo(player) {
  var s = $.sprintf(
    '<tr><td width="16">%s</td><td>%s</td>',
    currentPlayerCursor(player.userId),
    player.username + (player.inGame ? '' : '(not in game)'));
  s += '<td>';
  if (player.currentTokenBadge && player.currentTokenBadge.raceName != null) {
    s += $.sprintf(
      '<img src="%s" title="%s" class="token"/>',
      getRaceImage(player.currentTokenBadge.raceName, 'token'), player.currentTokenBadge.raceName+'+'+player.currentTokenBadge.specialPowerName);
  }
  if (player.declinedTokenBadge && player.declinedTokenBadge.raceName != null) {
    if (player.currentTokenBadge && player.currentTokenBadge.raceName != null) s += '&nbsp;';
    s += $.sprintf(
      '<img src="%s" title="%s" class="token"/>',
      getRaceImage(player.declinedTokenBadge.raceName, 'token', 1), player.declinedTokenBadge.raceName+'+'+player.declinedTokenBadge.specialPowerName);
  }
  s += '</td></tr>';
  return s;
}

function getObjectsInHand(player) {
  var s = '<table id="tableInHand"><tbody>';
  if (player.currentTokenBadge && player.currentTokenBadge.raceName != null) {
    s += addRow([$.sprintf('<img src="%s"" class="token"/>', getRaceImage(player.currentTokenBadge.raceName, 'token')),
         $.sprintf('<a id="aTokensInHand">%d</a>', player.tokensInHand)]);
    switch (player.currentTokenBadge.specialPowerName) {
      case 'DragonMaster':
        s += addRow([$.sprintf('<img src="%s""/>', objects['dragon']), 1 - data.game.dragonAttacked]);
        break;
      case 'Heroic':
        s += addRow([$.sprintf('<img src="%s""/>', objects['hero']), 2]);
        break;
      case 'Fortified':
        s += addRow([$.sprintf('<img src="%s""/>', objects['fortified']), 1]);
        break;
      case 'Bivouacking':
        s += addRow([$.sprintf('<img src="%s""/>', objects['encampment']), 5]);
        break;
    }
  }
  s += '</tbody></table>';
  return s;
}

function addOurPlayerInfo(player) {
  var s = $.sprintf(
    '<tr><td class="smallLeft">Name:</td><td>%s</td></tr>' +
    '<tr><td class="smallLeft">In hand:</td><td>%s</td></tr>' +
    '<tr><td class="smallLeft">Coins:</td><td>%s</td></tr>',
    data.username,
    getObjectsInHand(player),
    showCoins(player.coins, 1, 0)
    );

  if (data.game.friendInfo != null && data.game.friendInfo.friendId != null && data.game.friendInfo.friendId == player.userId) {
    var tmp = new Player(data.game.friendInfo.diplomatId);
    s += $.sprintf('<tr><td class="smallLeft">Friend:</td><td>%s</td></tr>', tmp.username());
  }
  if (player.currentTokenBadge && player.currentTokenBadge.raceName != null) {
    s += $.sprintf(
      '<tr><td colspan="2">Active race:</td></tr><tr><td colspan="2">' +
      '<img src="%s" class="badge" title="%s"/><img src="%s" class="badge" title="%s"/>' +
      '</td></tr>',
      getRaceImage(player.currentTokenBadge.raceName, 'race'), player.currentTokenBadge.raceName,
      specialPowers[player.currentTokenBadge.specialPowerName], player.currentTokenBadge.specialPowerName);
  }
  if (player.declinedTokenBadge && player.declinedTokenBadge.raceName != null) {
    s += $.sprintf(
      '<tr><td colspan="2">Declined race:</td></tr><tr><td colspan="2">' +
      '<img src="%s" class="badge"title="%s"/><img src="%s" class="badge" title="%s"/>' +
      '</td></tr>',
      getRaceImage(player.declinedTokenBadge.raceName, 'race', 1), player.declinedTokenBadge.raceName,
      specialPowers[player.declinedTokenBadge.specialPowerName], player.declinedTokenBadge.specialPowerName);
  }
  s += '<tr><td colspan="2"> <div class="buttons"> <div onclick="cmdLeaveGame();">Leave</div>'+
       '<div onclick="cmdSaveGame();">Save</div></div></td></tr>';
  return s;
}

function currentPlayerCursor(playerId) {
  var tmp = new Player(playerId);
  return tmp.isActive()
    ? '<img src="/pics/currentPlayerCursor.png" />'
    : '';
}

function getRaceNameById(badgeId) {
  if (badgeId == null) return '';
  for (var j in data.game.players) {
    var cur = data.game.players[j];
    if (cur.currentTokenBadge && cur.currentTokenBadge.tokenBadgeId == badgeId)
      return cur.currentTokenBadge.raceName;
    if (cur.declinedTokenBadge && cur.declinedTokenBadge.tokenBadgeId == badgeId)
      return cur.declinedTokenBadge.raceName;
  }
}

function getMapName(mapId) {
  if (maps[mapId]) return maps[mapId].name
  else return $.sprintf("<span class='_tmpMap_%s'>...</span>", mapId);
}

function makeCurrentGame(game) {
  with (game) {
    $("#cgameName").html(name);
    $("#cgameDescription").html(description);
    $("#cgameMap").html(getMapName(mapId));
    $("#cgameTurnsNum").html(turnsNum);
  }
  showCurrentGame();
}

function setGame(gameId) {
  data.gameId = gameId;
  _setCookie(["gameId"], [gameId]);
  makeCurrentGame(games[gameId]);
  cmdGetGameState();
}

function clearGame() {
  data.gameId = null;
  data.game = null;
  _setCookie(["gameId"], [null]);
  regions = [];
  if (canvas) {
    canvas.remove();
    canvas = null;
  }
}

function getSVGPath(region) {
  var s = '';
  for (var j in region.coordinates) {
    s += (j == 0 ? "M" : "L") + region.coordinates[j][0] + " " + region.coordinates[j][1];
  }
  s += "Z";
  return s;
}