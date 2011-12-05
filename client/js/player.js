var player = getPlayer(data.playerId);

function getPlayer(gs, playerId) {
  for (var i in gs.players) {
    this.p = gs.players[i];
    if (this.p.userId == playerId) break;
  }

  this.curTokenBadgeId = function() {
    return this.p.currentTokenBadge.tokenBadgeId;
  };
  this.curRace = function() {
    return this.p.currentTokenBadge.raceName;
  };
  this.coins = function() {
  return this.p.coins;
  };
  this.tokens = function() {
    return this.p.tokensInHand;
  };
  this.addTokens = function(tokens) {
    this.p.tokensInHand += tokens;
    $('#aTokensInHand').html(this.p.tokensInHand).trigger('update');
  };
  this.beforeRedeploy = function() {
    if (this.curRace == 'Amazons') {
      this.addTokens(-4);
    }
  };
  this.canAttack = function(regionId) {
  };
}
