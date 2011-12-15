[
        { "action": "resetServer" },
	{ "action": "uploadMap", "mapName": "testMap", "playersNum": 2, "turnsNum": 5, "regions": 
          [
		{ "landDescription": ["sea", "border"], "adjacent": [2, 6] },
		{ "landDescription": ["sea", "border"], "adjacent": [1, 3, 7] },
		{ "landDescription": ["coast", "border"], "adjacent": [2, 4, 8] },
		{ "landDescription": ["hill", "border", "cavern"], "adjacent": [3, 5, 9] },
		{ "landDescription": ["swamp", "border"], "adjacent": [4, 10] },
		{ "landDescription": ["mountain", "border", "mine"], "adjacent": [1, 7, 11] },
		{ "landDescription": ["coast", "magic"], "adjacent": [2, 6, 8, 12] },
		{ "landDescription": ["farmland"], "adjacent": [3, 7, 9, 13] },
		{ "landDescription": ["forest", "magic"], "adjacent": [4, 8, 10, 14] },
		{ "landDescription": ["sea", "border"], "adjacent": [5, 9, 15] },
		{ "landDescription": ["hill", "border", "mine"], "adjacent": [6, 12] },
		{ "landDescription": ["cavern", "border"], "adjacent": [7, 11, 13] },
		{ "landDescription": ["forest", "border"], "adjacent": [8, 12, 14] },
		{ "landDescription": ["cavern", "border", "mountain"], "adjacent": [9, 13, 15] },
		{ "landDescription": ["magic", "border"], "adjacent": [10, 14] }
	  ]
	},
        { "action": "register", "username": "username1", "password": "password" },
        { "action": "login", "username": "username1", "password": "password" },
        { "action": "register", "username": "username2", "password": "password" },
        { "action": "login", "username": "username2", "password": "password" },
        { "action": "register", "username": "username3", "password": "password" },
        { "action": "login", "username": "username3", "password": "password" },
        { "action": "createGame", "sid": 1, "gameName": "game1", "mapId": 1, "gameDescr": "description1" },
        { "action": "joinGame", "sid": 2, "gameId": 1 },
        { "action": "setReadinessStatus", "sid": 1, "isReady": 1 }
]
