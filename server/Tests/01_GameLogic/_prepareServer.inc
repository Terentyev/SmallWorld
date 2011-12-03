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
            "Amazons",   "Dwarves", "Elves",       "Giants",   "Halflings", "Humans",       "Orcs",   "Ratmen", "Skeletons", "Sorcerers", "Tritons", "Trolls",   "Wizard" ],
          "visibleSpecialPowers": [
            "Alchemist", "Berserk", "Bivouacking", "Commando", "Diplomat",  "DragonMaster", "Flying", "Forest", "Fortified", "Heroic",    "Hill",    "Merchant", "Mounted", "Pillaging", "Seafaring", "Stout", "Swamp", "Underworld", "Wealthy" ] }
]
