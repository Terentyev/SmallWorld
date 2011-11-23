[
        { "action": "resetServer" },
        { "action": "register", "username": "username1", "password": "password" },
        { "action": "login", "username": "username1", "password": "password" },
        { "action": "register", "username": "username2", "password": "password" },
        { "action": "login", "username": "username2", "password": "password" },
        { "action": "createDefaultMaps", "sid": 1 },
        { "action": "createGame", "sid": 1, "gameName": "game1", "mapId": 1, "gameDescr": "description1" },
        { "action": "joinGame", "sid": 2, "gameId": 1 },
        { "action": "setReadinessStatus", "sid": 1, "isReady": 1 },
        { "action": "setReadinessStatus", "sid": 2, "isReady": 1, "visibleRaces": [
            "amazons",   "dwarves", "elves",       "giants",   "halflings", "humans",       "orcs",   "ratmen", "skeletons", "sorcerers", "tritons", "trolls",   "wizard" ],
          "visibleSpecialPowers": [
            "alchemist", "berserk", "bivouacking", "commando", "diplomat",  "dragonMaster", "flying", "forest", "fortified", "heroic",    "hill",    "merchant", "mounted", "pillaging", "seafaring", "stout", "swamp", "underworld", "wealthy" ] }
]
