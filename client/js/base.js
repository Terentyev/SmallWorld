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

function showError(error, container) {
  if (container) $(container).html(error);
  else alert(error);
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
	  success: function(response)	{
		  if (!response.result)
			  showError("Unknown server response: " + JSON.stringify(response));
		  else if (response.result == 'ok')
		    callback(response);
		  else
        showError(response.result, errorContainer);
		  //alert(JSON.stringify(response));
      $.unblockUI();
    },
    error: function(jqXHR, textStatus, errorThrown) {
      $.unblockUI();
      alert(textStatus);
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
