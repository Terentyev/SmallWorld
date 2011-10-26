[
        { "action": "resetServer" },
        { "action": "uploadMap", "mapName": "map1", "playersNum": 2, "turnsNum": 5, "regions": [
            { "population": 1, "landDescription": ["coast"], "adjacent": [2, 3] },
            { "landDescription": ["sea", "border"], "adjacent": [1] },
            { "population": 1, "landDescription": ["mountain", "border"], "adjacent": [1, 4] },
            { "landDescription": ["lake", "border"], "adjacent": [3] },
            { "population": 1, "landDescription": ["hill", "mine"], "adjacent": [3] } ] 
        },
        { "action": "register", "username": "username1", "password": "password" },
        { "action": "login", "username": "username1", "password": "password" },
        { "action": "register", "username": "username2", "password": "password" },
        { "action": "login", "username": "username2", "password": "password" },
        { "action": "register", "username": "username3", "password": "password" },
        { "action": "login", "username": "username3", "password": "password" },
        { "action": "createGame", "sid": 1, "gameName": "game1", "mapId": 1 },
        { "action": "joinGame", "gameId": 1, "sid": 2},
        { "action": "setReadinessStatus", "sid": 2, "isReady": 1 }
]
