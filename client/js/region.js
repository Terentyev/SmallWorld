function Region(regionId) {
  this.r = data.game.map.regions[regionId];
}

Region.prototype.isOwned = function(tokenBadgeId) {
  return this.r.currentRegionState.tokenBadgeId == tokenBadgeId;
}

Region.prototype.is = function(type) {
  for (var i in this.r.constRegionState) {
    if (this.r.constRegionState[i] == type) {
      return true;
    }
  }
  return false;
}

Region.prototype.get = function(attr) {
  var result = this.r.currentRegionState[attr];
  return result == null ? 0 : result;
}

Region.prototype.isLand = function() {
  return !(this.isSea() || this.is('lake'));
}

Region.prototype.isSea = function() {
  return this.is('sea');
}

Region.prototype.isBorder = function() {
  return this.is('border');
}

Region.prototype.isCavern = function() {
  return this.is('cavern');
}

Region.prototype.isMountain = function() {
  return this.is('mountain');
}

Region.prototype.isFarmLand = function() {
  return this.is('farm');
}

Region.prototype.isHill = function() {
  return this.is('hill');
}

Region.prototype.adjacents = function() {
  var result = [];
  for (var i in this.r.adjacentRegions) {
    var cur = this.r.adjacentRegions[i];
    result[cur] = new Region(cur);
  }
  return result;
}

Region.prototype.tokens = function() {
  return this.r.currentRegionState.tokensNum;
}

Region.prototype.bonusTokens = function() {
  return 2 + this.get('fortified') + this.get('encampment') + this.get('lair') +
    (this.isMountain() ? 1 : 0);
}
