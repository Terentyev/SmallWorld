package AI::Player;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );

use SmallWorld::Checker qw( checkRegion_conquer );
use SmallWorld::Consts;
use SmallWorld::Game;
use SW::Util qw( swLog );

use AI::Config;
use AI::Output qw( printGames printDebug );


sub new {
  my $class = shift;
  my $self = {
    games => {}
  };

  bless $self, $class;
  $self->_init(@_);

  return $self;
}

sub _init {
  my $self = shift;
  my %p = (@_);
  $self->{req} = $p{req};
  if ( defined $p{game} && defined $p{ais} ) {
    $self->{games}->{$p{game}}->{ais} = eval { decode_json($p{ais}) } || [];
  }
}

sub _get {
  my ($self, $cmd, $add2log) = (@_, 0);
  return $self->{req}->get($cmd, $add2log);
}

sub do {
  my ($self, $game) = @_;
  if ( $game->{state} == GST_WAIT ) {
    $self->_join2Game($game);
    return;
  }

  if ( $self->_ourTurn($game) ) {
    $self->_play($game);
    return;
  }
}

sub printStatus {
  my $self = shift;
  printGames($self->games);
}

sub _join2Game {
  my ($self, $game) = @_;
  my $r = $self->_get('{ "action": "aiJoin", "gameId": ' . $game->{gameId} . ' }');
  return if $r->{result} ne R_ALL_OK;

  my $g = $self->games->{$game->{gameId}};
  if ( !defined $g ) {
    $g = { gs => undef, ais => [] };
  }
  push @{ $g->{ais} }, { id => $r->{id}, sid => $r->{sid} };
  $self->games->{$game->{gameId}} = $g;
}

sub _ourTurn {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  return 0 if !defined $g;

  my $r = $self->_get('{ "action": "getGameState", "gameId": ' . $game->{gameId} . ' }', 1);
  return 0 if $r->{result} ne R_ALL_OK;

  $g->{gs} = SmallWorld::Game->new(gameState => $r->{gameState});
  return (grep { $_->{id} == $g->{gs}->activePlayerId } @{ $g->{ais} });
}

sub _play {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  swLog(LOG_FILE, $g->{gs}->stage, $g->{gs}->activePlayerId);
  my $func = $self->can("_cmd_" . $g->{gs}->stage);
  &$func($self, $g) if defined $func;
}

sub _sendGameCmd {
  my $self = shift;
  my $cmd = {@_};
  my $g = delete $cmd->{game};
  foreach ( @{ $g->{ais} } ){
    if ( $_->{id} == $g->{gs}->activePlayerId ) {
      $cmd->{sid} = $_->{sid};
      last;
    }
  }
  die "Can't define sid of player\n" if !defined $cmd->{sid};
  $cmd = eval { encode_json($cmd) } || die "Can't encode json :(\n";
  $self->_get($cmd, 1);
}

sub _decline {
  my ($self, $g) = @_;
  $self->_sendGameCmd(game => $g, action => 'decline');
}

sub _canBaseAttack {
  my ($self, $g, $regionId) = @_;
  my $r = $g->{gs}->getRegion($regionId);
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return !$r->isImmune() &&
    $self->checkRegion_conquer(undef, $g->{gs}, $p, $r, $ar, $asp, undef);
}

sub _canAttack {
  my ($self, $g, $regionId) = @_;
  my $r = $g->{gs}->getRegion($regionId);
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return $self->_canBaseAttack($g, $regionId) && $g->{gs}->canAttack($p, $r, $ar, $asp, undef);
}

sub _cmd_defend {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  foreach ( @{ $p->activeRace()->regions } ) {
    last if $self->_sendGameCmd(
        game => $g,
        action => 'defend',
        regions => [
          {
            regionId => $_->{regionId},
            tokensNum => $p->tokens
          }
        ]
    )->{result} eq R_ALL_OK;
  }
}

sub _cmd_selectRace {
  my ($self, $g) = @_;
  my $p = int(rand(6));
  $self->_sendGameCmd(game => $g, action => 'selectRace', position => $p);
}

sub _cmd_beforeConquest {
  my ($self, $g) = @_;
  my $res = {};
  foreach ( @{ $g->{gs}->regions } ) {
    next if !$self->_canAttack($g, $_->{regionId});
    $res = $self->_sendGameCmd(game => $g, action => 'conquer', regionId => $_->{regionId});
    if ( $res->{result} eq R_ALL_OK ) {
      if ( $_->{ownerId} ) {
        # надо дать шанс защититься
        return;
      }
      # если мы в начале хода умудрились что-то захватить, то продолжаем завоевание
      $self->_cmd_conquest($g, 1);
      return;
    }
    if ( defined $res->{dice} ) {
      # если бросили кубики, то размещаем войска
#      $self->_cmd_redeploy($g);
      return;
    }
  }
  # у нас ничего не получилось завоевать, значит расу в упадок, ибо УГ
  $self->_decline($g);
}

sub _cmd_conquest {
  my ($self, $g, $i) = (@_, 0);
  my $res = {};
  foreach ( @{ $g->{gs}->regions } ) {
    next if !$self->_canAttack($g, $_->{regionId});
    $res = $self->_sendGameCmd(game => $g, action => 'conquer', regionId => $_->{regionId});
    if ( $res->{result} eq R_ALL_OK && defined $_->{ownerId} ) {
      # надо дать шанс защититься
      return;
    }
    if ( $res->{result} eq R_ALL_OK ) {
      $g->{gs}->getPlayer()->{dice} = $res->{dice};
      $g->{gs}->conquer($_->{regionId}, $res);
      ++$i;
    }
  }
  # размещаем войска
  $self->_cmd_redeploy($g);
}

sub _cmd_redeploy {
  my ($self, $g) = @_;
  $g->{gs}->gotoRedeploy();
  my $p = $g->{gs}->getPlayer();
  my $tokens = $p->tokens;
  my $regs = $p->activeRace()->regions;
  my @regions = ();
  $tokens += ($_->{tokens} // 0) for @$regs;
  my $n = scalar(@$regs);
  foreach ( @$regs ) {
    push @regions, { regionId => $_->{regionId}, tokensNum => $tokens / $n };
    $tokens -= $tokens / $n;
    if ( $tokens < $n ) {
      $regions[-1]->{tokensNum} += $tokens;
      last;
    }
  }
  $self->_sendGameCmd(game => $g, action => 'redeploy', regions => \@regions);
}

sub _cmd_beforeFinishTurn {
  my ($self, $g) = @_;
  $self->_sendGameCmd(game => $g, action => 'finishTurn');
}

sub _cmd_finishTurn {
  my ($self, $g) = @_;
  $self->_sendGameCmd(game => $g, action => 'finishTurn');
}

sub _cmd_gameOver {
  my ($self, $g) = @_;
  $self->_sendGameCmd(game => $g, action => 'leaveGame');
  for ( my $i = 0; $i < scalar(@{ $g->{ais} }); ++$i ) {
    if ( $g->{ais}->[$i]->{id} == $g->{gs}->activePlayerId ) {
      delete $g->{ais}->[$i];
      last;
    }
  }
}

sub games { return $_[0]->{games}; }

1;

__END__
