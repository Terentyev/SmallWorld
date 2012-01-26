function hoverRegion(region, isOver) {
  return function() {
    region.animate({'stroke-width': 2 + isOver * 2}, 100);
  }
}

function Region(regionId, obj) {
  this.r = data.game.map.regions[regionId];
  this._regionId = regionId;
  this.model = {
    'region': obj,
    'race': {
      'image': null,
      'num': null
    },
    'sp': {
      'count': 0
    }
  }
  this.raceName = getRaceNameById(this.r.currentRegionState.tokenBadgeId);
  this.createToken(this.r, this.raceName);
  for (var i in objects) {
    if (this.r.currentRegionState[i]) this.createObject(i, this.r.currentRegionState[i]);
  }
}

Region.prototype.regionId = function() {
  return this._regionId;
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

Region.prototype.set = function(attr, value) {
  this.r.currentRegionState[attr] = value;
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

Region.prototype.isImmune = function() {
  return this.r.currentRegionState.dragon ||
    this.r.currentRegionState.holeInTheGround ||
    this.r.currentRegionState.hero;
}

Region.prototype.adjacents = function() {
  var result = [];
  for (var i in this.r.adjacentRegions) {
    var cur = this.r.adjacentRegions[i];
    result.push(cur);
  }
  return result;
}

Region.prototype.isAdjacent = function(regionId) {
  for (var i in this.r.adjacentRegions) {
    if (this.r.adjacentRegions[i] == regionId) {
      return true;
    }
  }
  return false;
}

Region.prototype.tokens = function() {
  return this.r.currentRegionState.tokensNum || 0;
}

Region.prototype.rmTokens = function(tokens) {
  this.r.currentRegionState.tokensNum -= tokens;
  this.setTokenNum(this.tokens(), this.model.race.num, this.model.race.image);
}

Region.prototype.bonusTokens = function() {
  return 2 + this.get('fortified') + this.get('encampment') +
        (this.raceName == 'Trolls') + (this.isMountain() ? 1 : 0);
}

Region.prototype.conquerByPlayer = function(p, dice) {
  dice = dice || 0;
  var newTokens = Math.max(1, this.tokens() + this.bonusTokens() - dice - p.conquestBonusTokens(this));
  with (this.r.currentRegionState) {
    ownerId = p.userId();
    tokenBadgeId = p.curTokenBadgeId();
    tokensNum = newTokens;
    p.addTokens(-newTokens);
    inDecline = false;
    this.raceName = getRaceNameById(p.curTokenBadgeId());
  }
  this.setToken(this.raceName, newTokens, false);
}

Region.prototype.needDefend = function(){
  if (this.r.currentRegionState == null || this.r.currentRegionState.ownerId == null) return false;
  var tmp = new Player(this.r.currentRegionState.ownerId);
  return this.tokens() > 0 || tmp.myRegions().length > 1 ||
         tmp.curRace() == 'Elves' && tmp.curTokenBadgeId() == this.r.currentRegionState.tokenBadgeId;
}

Region.prototype.setTokenNum = function(num, numStore, imgStore) {
  if (!imgStore) return;
  var txt = num > 1 ? num: '';
  numStore.attr('text', txt);
  if (num) imgStore.show()
  else imgStore.hide()
}

Region.prototype.setDefendTokenNum = function(num) {
  if (!num) {
    this.setTokenNum(this.tokens(), this.model.race.num, this.model.race.image);
    return;
  }
  this.model.race.num.attr('text', this.tokens() + '+' + num);
}

Region.prototype.createObject = function(object, num) {
  var x = maps[data.game.map.mapId].regions[this.regionId()].powerCoords[0] + this.model.sp.count * (tokenWidth + 2),
      y = maps[data.game.map.mapId].regions[this.regionId()].powerCoords[1];
  this.model.sp[object] = canvas.image(objects[object].src, x, y, tokenWidth, tokenHeight).attr('title', objects[object].title);
  this.model.sp[object].mouseover(hoverRegion(this.model.region, true));
  this.model.sp[object].click( makeFuncRef(areaClick, this.regionId()) );
  if (object == 'encampment') {
    this.model.sp.num = canvas.text(x + tokenWidth/2, y + tokenHeight/2, '').attr(textAttr);
    this.setTokenNum(num, this.model.sp.num, this.model.sp[object]);
  }
  ++this.model.sp.count;
}

Region.prototype.deleteObject = function(object) {
  this.model.sp[object].remove();
  if (object == 'encampment') this.model.sp.num.remove();
  --this.model.sp.count;
}

Region.prototype.createToken = function(region, raceName) {
  var x = maps[data.game.map.mapId].regions[this.regionId()].raceCoords[0],
      y = maps[data.game.map.mapId].regions[this.regionId()].raceCoords[1],
      img = getRaceImage(raceName, 'token', region.currentRegionState.inDecline);
  this.model.race.image = canvas.image(img, x, y, tokenWidth, tokenHeight).attr('title', raceName);
  this.model.race.num = canvas.text(x + tokenWidth/2, y + tokenHeight/2, '').attr(textAttr);
  this.model.race.image.mouseover(hoverRegion(this.model.region, true));
  this.model.race.num.mouseover(hoverRegion(this.model.region, true));

  this.model.race.image.click( makeFuncRef(areaClick, this.regionId()) );
  this.setTokenNum(region.currentRegionState.tokensNum, this.model.race.num, this.model.race.image)
}

Region.prototype.setToken = function(raceName, num, inDecline) {
  this.model.race.image.attr({'src': getRaceImage(raceName, 'token', inDecline), 'title': raceName});
  this.setTokenNum(num, this.model.race.num, this.model.race.image);
}

Region.prototype.update = function(region) {
  for (var i in objects) {
    if (this.r.currentRegionState[i] != region.currentRegionState[i]) {
      if (this.r.currentRegionState[i]) {
        if (region.currentRegionState[i])
          this.setTokenNum(region.currentRegionState[i], this.model.sp.num, this.model.sp[i]); //encampments only;
        else
          this.deleteObject(i);
      } else this.createObject(i, region.currentRegionState[i]);
    }
  }
  var tokenBadgeId = this.r.currentRegionState.tokenBadgeId,
      newTokensNum = region.currentRegionState.tokensNum == null ? 0 : region.currentRegionState.tokensNum,
      newInDecline = region.currentRegionState.inDecline == null ? false : region.currentRegionState.inDecline;
  this.raceName = getRaceNameById(region.currentRegionState.tokenBadgeId);
  if (tokenBadgeId != region.currentRegionState.tokenBadgeId) {
    if (tokenBadgeId == null) {
      //if previous owner was lost tribe this.model.race.image already exists
      if (this.model.race.image == null || this.model.race.image.removed)
        this.createToken(region, this.raceName);
      else
        this.setToken(this.raceName, newTokensNum, newInDecline);
    } else if (region.currentRegionState.tokenBadgeId == null) {
      //remove old
      this.model.race.image.remove();
      this.model.race.num.remove();
    } else {
      //replace old
      this.setToken(this.raceName, newTokensNum, newInDecline);
    }
  } else if (this.tokens() != newTokensNum || this.get('inDecline') != newInDecline) {
    this.setToken(this.raceName, newTokensNum, newInDecline);
  }
  this.r.currentRegionState = region.currentRegionState;
  this.r.currentRegionState.tokensNum = newTokensNum;
  this.r.currentRegionState.inDecline = newInDecline;
}
