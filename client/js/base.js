var serverUrl = null;
var cmdErrors = {
  'badUsername':'Bad username',
  'badPassword':'Bad password',
  'usernameTaken': 'Username already taken',
  'badUserSid': 'You are not logged in',
  'badUsernameOrPassword': 'Wrong username or password'
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
  else return $.sprintf("<span class='_tmpMap_%s'>...</span>", mapId)
}
