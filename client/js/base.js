var serverUrl = null;
var cmdErrors = {
  'badUsername':'Bad username',
  'badPassword':'Bad password',
  'usernameTaken': 'Username already taken',
  'badUserSid': 'You are not loged in',
  'badUsernameOrPassword': 'badUsernameOrPassword error'
};

messages = new Array();
maps = new Array();
games = new Array();
maxMessagesCount = 5;
var data = {
      playerId: null,
      username: null,
      gameId: null,
      gameName: null,
      mapId: null,
      sid: 0
    };

function sendRequest(query, callback) {
  $.ajax({
  	type: "POST",
	  url: "http://client.smallworld",
	  dataType: "JSON",
	  timeout: 10000,
    data: {request: JSON.stringify(query), address: serverUrl},
    beforeSend: function() {
      $.blockUI({ message: '<h3><img src="/client/pics/loading.gif" /> Loading...</h3>' });
    },
	  success: function(response)	{
		  if (!response['result']) {
			  alert("Unknown server response: " + JSON.stringify(response));
			  return;
		  }
		  //alert(JSON.stringify(response));
		  callback(response);
		 	$.unblockUI();
	  },
	  error: function(jqXHR, textStatus, errorThrown) {
      $.unblockUI();
	  	alert(textStatus);
   	}
  });
}

function _setCookie(key, value) {
  for (var i in key)
    $.cookie(key[i], value[i]);
}


