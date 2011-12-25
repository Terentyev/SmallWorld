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
use AI::Consts;
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

  if ( $game->{state} == GST_FINISH ) {
    my $ais = $self->games->{$game->{gameId}}->{ais};
    $self->_leaveGame($game) if defined $ais && scalar(@$ais);
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

sub _leaveGame {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  for ( my $i = 0; $i < scalar(@{ $g->{ais} }); ++$i ) {
    $self->_sendGameCmd(game => $g, action => 'leaveGame', sid => $g->{ais}->[$i]->{sid});
  }
  $g->{ais} = [];
}

sub _ourTurn {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  return 0 if !defined $g;

  my $r = $self->_get('{ "action": "getGameState", "gameId": ' . $game->{gameId} . ' }', 1);
  return 0 if $r->{result} ne R_ALL_OK;

  $g->{gs} = SmallWorld::Game->new(gameState => $r->{gameState});
  return (grep { $_->{id} == ($g->{gs}->activePlayerId // -1) } @{ $g->{ais} });
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
  if ( !defined $cmd->{sid} ) {
    foreach ( @{ $g->{ais} } ){
      if ( $_->{id} == $g->{gs}->activePlayerId ) {
        $cmd->{sid} = $_->{sid};
        last;
      }
    }
  }
  die "Can't define sid of player\n" if !defined $cmd->{sid};
  $cmd = eval { encode_json($cmd) } || die "Can't encode json :(\n";
  $self->_get($cmd, 1);
}

sub _decline {
  my ($self, $g) = @_;
  die 'Fail decline' if
    $self->_sendGameCmd(game => $g, action => 'decline')->{result} ne R_ALL_OK;
}

sub _useSpConquer {
  my ($self, $g, $regionId, $ans) = @_;
  if ( $self->_canEnchant($g, $regionId) ) {
    $ans = $self->_sendGameCmd(game => $g, action => 'enchant', regionId => $regionId);
    die "Fail enchant" if $ans->{result} ne R_ALL_OK;
    $g->{gs}->enchant($regionId);
    return 1;
  }
  if ( $self->_canDragonAttack($g, $regionId) ) {
    $ans = $self->_sendGameCmd(game => $g, action => 'dragonAttack', regionId => $regionId);
    die "Fail dragon attack" if $ans->{result} ne R_ALL_OK;
    $g->{gs}->dragonAttack($regionId);
    return 1;
  }
  if ( $self->_canThrowDice($g) ) {
    $ans = $self->_sendGameCmd(game => $g, action => 'throwDice');
    die "Fail throw dice" if $ans->{result} ne R_ALL_OK;
    $g->{gs}->throwDice($ans->{dice});
    return 0;
  }
  return 0;
}

sub _canEnchant {
  my ($self, $g, $regionId) = @_;
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace;
  my $r = $g->{gs}->getRegion($regionId);
  return $self->_canBaseAttack($g, $regionId) &&
    $ar->canCmd('enchant', $g->{gs}->{gameState}) &&
    !$r->inDecline && $r->tokens == 1 && !$r->encampment;
}

sub _canDragonAttack {
  my ($self, $g, $regionId) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  my $js = { action => 'dragonAttack' };
  return $self->_canBaseAttack($g, $regionId) &&
    $asp->canCmd($js, $g->{gs}->state, $p);
}

sub _canThrowDice {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  my $js = { action => 'throwDice' };
  return $asp->canCmd($js, $g->{gs}->state, $p);
}

sub _conquerRegion {
  my ($self, $g, $regionId, $ans) = @_;
  return 1 if $self->_useSpConquer($g, $regionId, $ans);
  # TODO: сделать с учетом бросания кубика и подсчета вероятности
  return 0 if !$self->_canAttack($g, $regionId);
  $ans = $self->_sendGameCmd(game => $g, action => 'conquer', regionId => $regionId);
  return 1;
}

sub _conquer {
  my ($self, $g) = @_;
  my $res = NOT_CONQUERED;
  my $ans = {};
  my $dummy = {};
  my $repeat = 0;
  do {
    $repeat = 0;
    foreach ( @{ $g->{gs}->regions } ) {
      next if !$self->_conquerRegion($g, $_->{regionId}, $ans);
      # если это было последнее завоевание, то возможна одна из ситуаций:
      #  1. У нас есть региона -> redeploy
      #  2. У нас нет регионов -> beforeFinishTurn
      # Пока не будем мудрить и спросим сервер, какое у нас состояние
      return ABORT if defined $ans->{dice};
      # если захватить не получилось, то пытаемся захватить следующий регион
      next if $ans ne R_ALL_OK;
      # надо дать шанс защититься, если регион пренадлежал расе не в упадке
      return ABORT if $ans eq R_ALL_OK && !$_->{inDecline};
      # состояние игры изменилось на conquest, поэтому продолжаем воевать там
      $res = CONQUERED;
      $repeat = 1; # надо повторить, вдруг сможем ещё что-то захватить
      # изменяем все состояние согласно правилам
      $g->{gs}->conquer($_->{regionId}, $dummy);
    }
  } while ( $repeat );
  return $res;
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
  $p->{dice} = defined $g->{gs}->berserkDice ? 0 : 3; # максимум возможное # TODO: переделать
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return $self->_canBaseAttack($g, $regionId) && $g->{gs}->canAttack($p, $r, $ar, $asp, {});
}

sub _cmd_defend {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  foreach ( @{ $p->activeRace()->regions } ) {
    return if $self->_sendGameCmd(
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
  die 'Fail defend';
}

sub _cmd_selectRace {
  my ($self, $g) = @_;
  my $p = int(rand(6));
  die 'Fail select race' if
    $self->_sendGameCmd(game => $g, action => 'selectRace', position => $p)->{result} ne R_ALL_OK;
}

sub _cmd_beforeConquest {
  my ($self, $g) = @_;
  my $res = $self->_conquer($g);
  return if $res == ABORT;
  # размещаем войска
  return $self->_cmd_redeploy($g) if $res == CONQUERED;
  # у нас ничего не получилось завоевать и состояние игры не изменилось, значит
  # расу в упадок, ибо УГ
  $self->_decline($g);
}

sub _cmd_conquest {
  my ($self, $g, $i) = (@_, 0);
  my $res = $self->_conquer($g);
  return if $res == ABORT;
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
    push @regions, { regionId => $_->{regionId}, tokensNum => int($tokens / $n) };
    $tokens -= int($tokens / $n);
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

sub games { return $_[0]->{games}; }

1;

__END__
