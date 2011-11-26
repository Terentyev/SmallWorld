var serverUrl = null;
var cmdErrors = {
  'badUsername': 'Bad username',
  'badPassword': 'Bad password',
  'usernameTaken': 'Username already taken',
  'badUserSid': 'You are not logged in',
  'badUsernameOrPassword': 'Wrong username or password'
};
var races = {
  'amazons': '/pics/raceAmazons.png',
  'dwarves': '/pics/raceDwarves.png',
  'elves': '/pics/raceElves.png',
  'giants': '/pics/raceGiants.png',
  'halflings': '/pics/raceHalflings.png',
  'humans': '/pics/raceHumans.png',
  'orcs': '/pics/raceOrcs.png',
  'ratmen': '/pics/raceRatmen.png',
  'skeletons': '/pics/raceSkeletons.png',
  'sorcerers': '/pics/raceSorcerers.png',
  'tritons': '/pics/raceTritons.png',
  'trolls': '/pics/raceTrolls.png',
  'wizards': '/pics/raceWizards.png'
};
var specialPowers = {
  'alchemist': '/pics/spAlchemist.png',
  'berserk': '/pics/spBerserk.png',
  'bivouacking': '/pics/spBivouacking.png',
  'commando': '/pics/spCommando.png',
  'diplomat': '/pics/spDiplomat.png',
  'dragonMaster': '/pics/spDragonMaster.png',
  'flying': '/pics/spFlying.png',
  'forest': '/pics/spForest.png',
  'fortified': '/pics/spFortified.png',
  'heroic': '/pics/spHeroic.png',
  'hill': '/pics/spHill.png',
  'merchant': '/pics/spMerchant.png',
  'mounted': '/pics/spMounted.png',
  'pillaging': '/pics/spPillaging.png',
  'seafaring': '/pics/spSeafaring.png',
  'stout': '/pics/spStout.png',
  'swamp': '/pics/spSwamp.png',
  'underworld': '/pics/spUnderworld.png',
  'wealthyt': '/pics/spWealthy.png'
};

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
var needMakeCurrent = false;

function showError(errorText, container) {
  if (container) $(container).html(errorText);
  else alert(errorText);
}

function sendRequest(query, callback, errorContainer) {
  $.ajax({
    type: "POST",
    url: "http://client.smallworld",
    dataType: "JSON",
    timeout: 10000,
    data: {request: JSON.stringify(query), address: serverUrl},
    beforeSend: function() {
      $.blockUI({ message: '<h3><img src="./pics/loading.gif" /> Loading...</h3>' });
    },
    success: function(response)  {
      if (!response || !response.result)
        showError("Unknown server response: " + JSON.stringify(response));
      else if (response.result == 'ok') {
        if (callback) callback(response);
      } else
        showError(response.result, errorContainer);
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
  _setCookie(["gameId"], gameId);
  makeCurrentGame(games[gameId]);
  if (games[gameId].inGame) {
    cmdGetGameState(hdlGetGameState);
  }
}
