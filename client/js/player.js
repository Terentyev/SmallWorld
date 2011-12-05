var player = {
  p: null,
  updatePlayer: function(gs) {
    for (var i in gs.players) {
      this.p = gs.players[i];
      if (this.p.userId == data.playerId) break;
    }
    return this.p;
  },
  curTokenBadgeId: function() {
    return this.p.currentTokenBadge.tokenBadgeId;
  },
  curRace: function() {
    return this.p.currentTokenBadge.raceName;
  },
  coins: function() {
    return this.p.coins;
  },
  tokens: function() {
    return this.p.tokensInHand;
  },
  addTokens: function(tokens) {
    this.p.tokensInHand += tokens;
    $('#aTokensInHand').html(this.p.tokensInHand).trigger('update');
  }
};
