var player = null;

function Player(playerId, gs) {
  this.gs = gs;
  if (this.gs == null) {
    this.gs = data.game;
  }
  var inGame = false;
  this.p = null;
  for (var i in this.gs.players) {
    if (this.gs.players[i].userId == playerId) {
      inGame = true;
      this.p = this.gs.players[i];
      break;
    }
  }
  if (!inGame) return;

  //количество объектов на регионах с активной расой
  this.objectCount = {
    'hero': 0,
    'fortified': 0,
    'encampment': 0
  };

  for (var i in this.gs.map.regions) {
    var cur = this.gs.map.regions[i].currentRegionState;
    if (cur.tokenBadgeId && this.p.currentTokenBadge && cur.tokenBadgeId == this.p.currentTokenBadge.tokenBadgeId) {
      for (var j in this.objectCount)
        this.objectCount[j] += cur[j] || 0;
    }
  }
  this.p.berserkDice = this.curPower == 'Berserk' ? this.gs.berserkDice: null;
  this.p.enchanted = (this.curRace() == 'Sorcerers' && this.gs.enchanted != null) ? this.gs.enchanted : false;
  this.p.dragonAttacked = (this.curPower == 'DragonMaster' && this.gs.dragonAttacked != null) ? this.gs.dragonAttacked : false;
  this.p.friendId = null;
  if (this.gs.friendInfo != null && this.gs.friendInfo.friendId == playerId)
    this.p.friendId = this.gs.friendInfo.diplomatId;
}

Player.prototype.userId = function() {
  return this.p ? this.p.userId : -1;
}

Player.prototype.username = function() {
  return this.p ? this.p.username : '';
}

Player.prototype.inGame = function() {
  return this.p != null;
}

Player.prototype.isHe = function(playerId) {
  return playerId == this.userId();
}

Player.prototype.isActive = function() {
  return (this.isHe(this.gs.activePlayerId) && (this.gs.stage != 'defend') || this.isDefender()) ? 1 : 0;
}

Player.prototype.isDefender = function() {
  return (this.gs.stage == 'defend') &&
    ((this.gs.defendingInfo != null) && this.isHe(this.gs.defendingInfo.playerId)) ? 1 : 0;
}

Player.prototype.hasActiveRace = function() {
  return this.p != null && this.p.currentTokenBadge != null && this.p.currentTokenBadge.tokenBadgeId != null;
}

Player.prototype.curTokenBadgeId = function() {
  return this.hasActiveRace() ? this.p.currentTokenBadge.tokenBadgeId : -1;
}

Player.prototype.curRace = function() {
  return this.hasActiveRace() ? this.p.currentTokenBadge.raceName : '';
}

Player.prototype.curPower = function() {
  return this.hasActiveRace() ? this.p.currentTokenBadge.specialPowerName : '';
}

Player.prototype.coins = function() {
  return this.p.coins;
}

Player.prototype.tokens = function() {
  return this.p.tokensInHand;
}

Player.prototype.getObjectCount = function(object) {
  return this.objectCount[object] || 0;
}

Player.prototype.getObjectsInHand = function(object) {
  switch (object) {
    case 'encampment': return ENCAMPMENTS_MAX - this.objectCount.encampment;
    case 'hero': return HEROES_MAX - this.objectCount.hero;
    case 'fortified': return this.getLastFortifiedRegion() ? 0 : 1;
  }
}

Player.prototype.getLastFortifiedRegion = function(object) {
  return this.lastFortified || 0;
}

Player.prototype.canPlaceObject = function(regionId, object) {
  switch (this.curPower()) {
    case 'Bivouacking':
      if (this.objectCount.encampment >= ENCAMPMENTS_MAX) return false
      break;
    case 'Fortified':
      if (this.objectCount.fortified >= FORTRESSES_MAX ||
          (!this.getLastFortifiedRegion() && regions[regionId].get('fortified')) ||
          (this.getLastFortifiedRegion() && this.getLastFortifiedRegion() != regionId)) return false;
      break;
    case 'Heroic':
      if (this.objectCount.hero >= HEROES_MAX && !regions[regionId].get('hero')) return false;
  }

  return true;
}

Player.prototype.placeObject = function(regionId, object, num) {
  var old = regions[regionId].get(object);
  if (old) regions[regionId].deleteObject(object);
  if (num) regions[regionId].createObject(object, num);
  regions[regionId].set(object, num);
  this.objectCount[object] += num - old;
  if (object == 'fortified') this.lastFortified = num ? regionId: 0;
  $($.sprintf('#a%sInHand', object)).html(this.getObjectsInHand(object));
}

Player.prototype.removeObjects = function(regionId) {
  for (var i in objects) {
    if (regions[regionId].get(i) && i != 'dragon' && i != 'holeInTheGround') {
      this.objectCount[i] -= regions[regionId].get(i);
      regions[regionId].set(i, i == 'encampment' ? 0: false);
      regions[regionId].deleteObject(i);
      if (i == 'fortified') this.lastFortified = 0;
      $($.sprintf('#a%sInHand', i)).html(this.getObjectsInHand(i));
    }
  }
}

Player.prototype.setBerserkDice = function(dice) {
  this.p.berserkDice = dice;
}

Player.prototype.setDragonAttack = function() {
  this.p.dragonAttacked = true;
}

Player.prototype.setEnchant = function() {
  this.p.enchanted = true;
}

Player.prototype.getEnchant = function() {
  return this.p.enchanted;
}

Player.prototype.setRegionId = function(regionId) {
  this.p.regionId = regionId;
}

Player.prototype.getRegionId = function() {
  return this.p.regionId;
}

Player.prototype.addTokens = function(tokens) {
  this.p.tokensInHand += tokens;
  if (this.tokens() < 0) {
    // если на руках получилось отрицательное число, то надо "дополнить" руки
    // фигурками с регионов
    var regs = this.myRegions();
    for (var i in regs) {
      var t = Math.min(regions[regs[i]].tokens() - 1, -this.tokens());
      this.p.tokensInHand += t;
      regions[regs[i]].rmTokens(t);
      if (this.tokens() == 0) {
        break;
      }
    }
    var len = -this.tokens();
    for (var i = 0; i < len; ++i) {
      regions[regs[i]].rmTokens(1);
      this.p.tokensInHand ++;
    }
  }
  $('#aTokensInHand').html(this.tokens()).trigger('update');
}

Player.prototype.beforeRedeploy = function() {
  if (this.curRace() == 'Amazons') {
    this.addTokens(-4);
  }
}

Player.prototype.myRegions = function() {
  var result = [], r;
  for (var i in regions) {
    if (regions[i].isOwned(this.curTokenBadgeId())) {
      result.push(i);
    }
  }
  return result;
}

Player.prototype.berserkDice = function() {
  return this.p.berserkDice == null ? 0 : this.p.berserkDice;
}

Player.prototype.canBerserkThrowDice = function() {
  return this.p.berserkDice == null;
}

Player.prototype.conquestBonusTokens = function(region) {
  var result = 0;
  var adjs = region.adjacents();
  if (this.curRace() == 'Giants') {
    for (var i in adjs) {
      if (regions[adjs[i]].isOwned(this.curTokenBadgeId()) && regions[adjs[i]].isMountain()) {
        result += 1;
        break;
      }
    }
  }

  if (this.curRace() == 'Tritons') {
    for (var i in adjs) {
      if (!regions[adjs[i]].isLand()) {
        result += 1;
        break;
      }
    }
  }

  result += this.berserkDice();

  if (this.curPower() == 'Commando') {
    result += 1;
  }

  if (this.curPower() == 'Mounted' && (region.isFarmLand() || region.isHill())) {
    result += 1;
  }

  if (this.curPower() == 'Underworld' && region.isCavern()) {
    result += 1;
  }

  return result;
}

Player.prototype.canThrowDice = function() {
  return this.p.berserkDice == null;
}

Player.prototype.canBaseAttack = function(regionId) {
  var region = regions[regionId];
  if (region.isOwned(this.curTokenBadgeId())) {
    alert("You can't conquer your owned region");
    return false;
  }

  if (region.isImmune()) {
    alert('Region is immune');
    return false;
  }

  if (this.p.friendId != null) {
    f = new Player(this.p.friendId, this.gs);
    if (region.isOwned(f.curTokenBadgeId())) {
      alert('You can\'t attack your friend active race');
      return false;
    }
  }

  if (!(this.curPower() == 'Seafaring' || region.isLand())) {
    alert("You can't conquer not land");
    return false;
  }

  var adjs = region.adjacents();
  var myRegions = this.myRegions();
  if (myRegions.length == 0) { // если первое завоевание
    if (this.curRace() == 'Halflings' || region.isLand()) {
      // полурослики могут захватывать любую сушу
      return true;
    }
    if (region.isBorder()) {
      // все могут захватывать на первом ходу границы
      return true;
    }
    for (var i in adjs) {
      if (regions[adjs[i]].isBorder() && regions[adjs[i]].isSea()) {
        // все могут захватывать на первом ходу регионы, которые граничат с
        // морскими границами
        return true;
      }
    }
    alert("You can't conquer this region on first conquest");
    return false;
  }

  if (this.curPower() == 'Flying') {
    // обладатели умения Flying могут захватывать любую сушу
    return true;
  }

  if (this.curPower() == 'Underworld' && region.isCavern() &&
      $.grep(myRegions, function(o) { return regions[o].isCavern(); }).length != 0) {//TODO test
    // обладатели умения Underworld могут захватывать регион с пещерой, если у
    // них есть уже регион с пещерой
    return true;
  }

  var adjacent = false;
  for (var i in adjs) {
    if (regions[adjs[i]].isOwned(this.curTokenBadgeId())) {
      // нашли среди наших регионов тот, который граничит с регионом-жертвой
      adjacent = true;
      break;
    }
  }

  if (!adjacent) {
    // можно нападать только на граничные нашим регионы
    alert('You should conquer only adjacent regions');
    return false;
  }
  return true;
}

Player.prototype.canDragonAttack = function(regionId) {
  return !this.p.dragonAttacked && this.canBaseAttack(regionId) && this.tokens();
}

Player.prototype.canEnchant = function(regionId) {
  if (this.p.enchanted || !this.canBaseAttack(regionId))
    return false;

  var r = regions[regionId];
  if (r.tokens() != 1) {
    alert("You shold enchant on region with 1 token");
    return false;
  }

  if (r.get('inDecline')) {
    alert("You can't enchant on declined race");
    return false;
  }

  if (r.get('encampment') > 0) {
    alert("You can't enchant on region with encampments");
    return false;
  }

  return true;
}

Player.prototype.canAttack = function(regionId) {
  if (!this.canBaseAttack(regionId)) {
    return false;
  }

  var region = regions[regionId];
  var tokensDiff = region.tokens() + region.bonusTokens() - this.tokens() - this.conquestBonusTokens(region);
  if (this.tokens() < 1 || tokensDiff > 0 && (!this.canThrowDice() || tokensDiff > 3)) {
    alert('Not enough tokens for conquest this region');
    return false;
  }

  return (tokensDiff <= 0) || confirm('Not enough tokens for conquest. Do you want to throw dice?');
}

Player.prototype.canAutoFinishTurn = function() {
  return this.curPower() != 'Diplomat' && this.curPower() != 'Stout';
}