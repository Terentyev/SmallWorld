var player = null;

function Player(playerId, gs) {
  this.gs = gs;
  if (this.gs == null) {
    this.gs = data.game;
  }
  for (var i in this.gs.players) {
    this.p = this.gs.players[i];
    if (this.p.userId == playerId) return;
  }
  this.p = null;
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

Player.prototype.setBerserkDice = function(dice) {
  this.p.berserkDice = dice;
}

Player.prototype.setSelectFriend = function() {
  // TODO
}

Player.prototype.setDragonAttack = function() {
  // TODO
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

  if (!(this.curPower() == 'Seafaring' || region.isLand())) {
    alert("You can't conquer not land")
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
  // TODO: дополнительные проверки
  return this.canBaseAttack(regionId);
}

Player.prototype.canAttack = function(regionId) {
  if (!this.canBaseAttack(regionId)) {
    return false;
  }

  var region = regions[regionId];
  var tokensDiff = region.tokens() + region.bonusTokens() - this.tokens() - this.conquestBonusTokens(region);
  if (this.tokens() < 1 || !this.canThrowDice() || tokensDiff > 3) {
    alert('Not enough tokens for conquest this region');
    return false;
  }

  return (tokensDiff <= 0) || confirm('Not enough tokens for conquest. Do you want to throw dice?');
}
