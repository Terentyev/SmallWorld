[
        { "action": "resetServer" },
	{ "action": "uploadMap", "mapName": "testMap", "playersNum": 2, "turnsNum": 5, "regions": 
          [
		{ "landDescription": ["sea", "border"], "adjacent": [3] },
		{ "population": 1, "landDescription": ["mountain", "border"], "adjacent": [3] },
		{ "landDescription": ["coast", "border"], "adjacent": [1, 2, 4] },
		{ "population": 1, "landDescription": ["hill"], "adjacent": [3, 5] },
		{ "landDescription": ["farmland", "border"], "adjacent": [4, 6] },
		{ "population": 1, "landDescription": ["forest"], "adjacent": [5] }
	  ]
	},
        { "action": "register", "username": "username1", "password": "password" },
        { "action": "login", "username": "username1", "password": "password" },
        { "action": "register", "username": "username2", "password": "password" },
        { "action": "login", "username": "username2", "password": "password" },
        { "action": "register", "username": "username3", "password": "password" },
        { "action": "login", "username": "username3", "password": "password" },
        { "action": "createGame", "sid": 1, "gameName": "game1", "mapId": 1, "gameDescription": "description1" },
        { "action": "joinGame", "sid": 2, "gameId": 1 },
        { "action": "setReadinessStatus", "sid": 1, "isReady": 1 },
        { "action": "setReadinessStatus", "sid": 2, "isReady": 1, "visibleRaces": [
            "Amazons", "Dwarves", "Elves", "Giants", "Halflings", "Humans", "Orcs", "Ratmen", "Skeletons", "Sorcerers", "Tritons", "Trolls", "Wizards" ],
          "visibleSpecialPowers": [
            "Alchemist", "Berserk", "Bivouacking", "Commando", "Diplomat",  "DragonMaster", "Flying", "Forest", "Fortified", "Heroic", "Hill", "Merchant", "Mounted", "Pillaging", "Seafaring", "Stout", "Swamp", "Underworld", "Wealthy" ] }
]
