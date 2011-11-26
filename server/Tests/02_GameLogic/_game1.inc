[
        { "action": "resetServer" },
	{ "action": "uploadMap", "mapName": "testMap", "playersNum": 2, "turnsNum": 5, "regions": 
          [
		{ "landDescription": ["sea", "border"], "adjacent": [3] },
		{ "population": 1, "landDescription": ["mountain", "border"], "adjacent": [3] },
		{ "landDescription": ["coast"], "adjacent": [1, 2, 4] },
		{ "population": 1, "landDescription": ["hill"], "adjacent": [3, 5] },
		{ "population": 1, "landDescription": ["farmland", "border"], "adjacent": [4] }
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
        { "action": "setReadinessStatus", "sid": 1, "isReady": 1 },
        { "action": "setReadinessStatus", "sid": 2, "isReady": 1, "visibleRaces": [
            "amazons",   "dwarves", "elves",       "giants",   "halflings", "humans",       "orcs",   "ratmen", "skeletons", "sorcerers", "tritons", "trolls",   "wizard" ],
          "visibleSpecialPowers": [
            "alchemist", "berserk", "bivouacking", "commando", "diplomat",  "dragonMaster", "flying", "forest", "fortified", "heroic",    "hill",    "merchant", "mounted", "pillaging", "seafaring", "stout", "swamp", "underworld", "wealthy" ] }
]
