package AI::Player;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );
use List::Util qw( max min );

use SmallWorld::Checker qw(
    checkRegion_conquer
    checkRegion_enchant
    checkFriend
);
use SmallWorld::Consts;
use SmallWorld::Game;
use SW::Util qw( swLog );

use AI::Config;
use AI::Consts;
use AI::DB;
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
  $self->{db} = AI::DB->new(
      db          => DB_NAME,
      user        => DB_LOGIN,
      passwd      => DB_PASSWORD,
      maxBlobSize => DB_MAX_BLOB_SIZE);
}

sub _get {
  my ($self, $cmd, $add2log) = (@_, 0);
  return $self->{req}->get($cmd, $add2log);
}

sub _save {
  my ($self, $g) = @_;
  $g->{gs}->dropObjects();
  my $state = {
    'regions' => [
      map { {
        regionId         => $_->{regionId},
        conquestIdx      => $_->{conquestIdx},
        prevTokensNum    => $_->{prevTokensNum},
        prevTokenBadgeId => $_->{prevTokenBadgeId}
      } } @{ $g->{gs}->regions }
    ],
  };
  $state = encode_json($state);
  my $where = { playerId => $g->{gs}->activePlayerId };
  if ( $self->{db}->select1(from => STATES_TABLE, fields => [ 1 ], where => $where) ) {
    $self->{db}->update(update => STATES_TABLE, set => { state => $state }, where  => $where);
  }
  else {
    $self->{db}->insert(into => STATES_TABLE, values => { %$where, state => $state });
  }
}

sub _load {
  my ($self, $g) = @_;
  my $state = $self->{db}->select1(
      from   => STATES_TABLE,
      fields => ['state'],
      where  => { playerId => $g->{gs}->activePlayerId });
  return if !defined $state;
  $state = decode_json($state);
  foreach ( @{ $state->{regions} // [] } ) {
    my $r = $g->{gs}->getRegion($_->{regionId});
    (@$r{qw(conquestIdx prevTokensNum prevTokenBadgeId)}) = (@$_{qw(conquestIdx prevTokensNum prevTokenBadgeId)});
  }
}

sub do {
  my ($self, $game) = @_;
  if ( $game->{state} == GST_WAIT ) {
    $self->_join2Game($game);
    return;
  }

  if ( $game->{state} == GST_FINISH ) {
    my $ais = $self->games->{$game->{gameId}}->{ais};
    $self->_allLeaveGame($game) if defined $ais && scalar(@$ais);
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

  # удалить все что касается данных о игре для нового игрока (если что-то
  # осталось)
  $self->{db}->delete(from => STATES_TABLE, where => { playerId => $r->{id} });
  my $g = $self->games->{$game->{gameId}};
  if ( !defined $g ) {
    $g = { gs => undef, ais => [] };
  }
  push @{ $g->{ais} }, { id => $r->{id}, sid => $r->{sid} };
  $self->games->{$game->{gameId}} = $g;
}

sub _allLeaveGame {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  for ( my $i = 0; $i < scalar(@{ $g->{ais} }); ++$i ) {
    $self->_leaveGame($g, $g->{ais}->[$i]->{sid});
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
  $self->_load($g);
  my $func = $self->can("_cmd_" . $g->{gs}->stage);
  &$func($self, $g) if defined $func;
  $self->_save($g);
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

sub _useSpConquer {
  my ($self, $g, $regionId, $ans) = @_;
  if ( $self->_canEnchant($g, $regionId) ) {
    $$ans = $self->_sendGameCmd(game => $g, action => 'enchant', regionId => $regionId);
    die "Fail enchant" if $$ans->{result} ne R_ALL_OK;
    $g->{gs}->enchant($regionId);
    return 1;
  }
  if ( $self->_canDragonAttack($g, $regionId) ) {
    $$ans = $self->_sendGameCmd(game => $g, action => 'dragonAttack', regionId => $regionId);
    die "Fail dragon attack" if $$ans->{result} ne R_ALL_OK;
    $g->{gs}->dragonAttack($regionId);
    return 1;
  }
  if ( $self->_canThrowDice($g) ) {
    $$ans = $self->_sendGameCmd(game => $g, action => 'throwDice');
    die "Fail throw dice" if $$ans->{result} ne R_ALL_OK;
    $g->{gs}->throwDice($$ans->{dice});
    return 0;
  }
  return 0;
}

sub _alienEncampNum {
  my ($self, $g) = @_;
  my $result = 0;
  foreach ( @{ $g->{gs}->regions } ) {
    $result += ($_->{encampment} // 0) if $_->{ownerId} != $g->{gs}->activePlayerId;
  }
  return $result;
}

sub _canBaseAttack {
  my ($self, $g, $regionId) = @_;
  my $r = $g->{gs}->getRegion($regionId);
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return !$r->isImmune() &&
    !$self->checkRegion_conquer(undef, $g->{gs}, $p, $r, $ar, $asp, undef);
}

sub _canAttack {
  my ($self, $g, $regionId) = @_;
  my $r = $g->{gs}->getRegion($regionId);
  my $p = $g->{gs}->getPlayer();
  my $dummy = {dice => defined $g->{gs}->berserkDice ? 0 : 3}; # максимум возможное # TODO: переделать
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return $self->_canBaseAttack($g, $regionId) && $g->{gs}->canAttack($p, $r, $ar, $asp, $dummy);
}

sub _canEnchant {
  my ($self, $g, $regionId) = @_;
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace;
  my $asp = $p->activeSp;
  my $r = $g->{gs}->getRegion($regionId);
  return !$self->checkRegion_enchant(undef, $g->{gs}, $p, $r, $ar, $asp, undef) &&
    $ar->canCmd('enchant', $g->{gs}->{gameState});
}

sub _canDragonAttack {
  my ($self, $g, $regionId) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $self->_canBaseAttack($g, $regionId) &&
    $asp->canCmd({ action => 'dragonAttack' }, $g->{gs}->stage, $p);
}

sub _canThrowDice {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'throwDice' }, $g->{gs}->stage, $p);
}

sub _canStoutDecline {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp();
  return $asp->canCmd({ action => 'decline' }, $g->{gs}->stage, $p);
}

sub _canSelectFriend {
  my ($self, $g, $playerId) = (@_, 0);
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  my $js = { action => 'selectFriend', friendId => $playerId };
  my $can = $asp->canCmd($js, $g->{gs}->stage, $p);
  return $can if !$can || $playerId == 0;
  return !$self->checkFriend($js, $g->{gs}, $p);
}

sub _canPlaceHero {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'redeploy', heroes => [] }, $g->{gs}->stage, $p);
}

sub _canPlaceEncampment {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'redeploy', encampments => [] }, $g->{gs}->stage, $p) &&
    $self->_alienEncampNum($g) < ENCAMPMENTS_MAX;
}

sub _canPlaceFortified {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'redeploy', fortified => {} }, $g->{gs}->stage, $p) &&
    scalar(grep $_->{fortified}, @{ $g->{gs}->regions }) < FORTRESS_MAX;
}

sub _needStoutDecline {
  # TODO: наверное, это уже будет продвинутый ИИ, если он будет решать нужно ли
  # ему приводить расу в упадок способностью Stout
  return !int(rand(5));
}

sub _conquerRegion {
  my ($self, $g, $regionId, $ans) = @_;
  return 1 if $self->_useSpConquer($g, $regionId, $ans);
  $$ans = {}; # надо очистить, чтобы мусора типа dice не было
  # TODO: сделать с учетом бросания кубика и подсчета вероятности
  return 0 if !$self->_canAttack($g, $regionId);
  $$ans = $self->_sendGameCmd(game => $g, action => 'conquer', regionId => $regionId);
  # изменяем все состояние согласно правилам
  if ( $$ans->{result} eq R_ALL_OK ) {
    $g->{gs}->getPlayer()->dice($$ans->{dice});
    $g->{gs}->conquer($regionId, {});
  }
  return 1;
}

sub _leaveGame {
  my ($self, $g, $sid) = @_;
  $self->_sendGameCmd(game => $g, action => 'leaveGame', sid => $sid);
}

sub _conquer {
  my ($self, $g) = @_;
  my $res = NOT_CONQUERED;
  my $ans = {};
  my $repeat = 0;
  do {
    $repeat = 0;
    foreach ( @{ $g->{gs}->regions } ) {
      my $needDefend = ($_->{tokenBadgeId} // 0) != 0 && !$_->{inDecline};
      next if !$self->_conquerRegion($g, $_->{regionId}, \$ans);
      swLog(LOG_FILE, '_conquer', $ans, $needDefend);
      # если это было последнее завоевание, то возможна одна из ситуаций:
      #  1. У нас есть региона -> redeploy
      #  2. У нас нет регионов -> beforeFinishTurn
      # Пока не будем мудрить и спросим сервер, какое у нас состояние
      return ABORT if defined $ans->{dice};
      # если захватить не получилось, то пытаемся захватить следующий регион
      next if $ans->{result} ne R_ALL_OK;
      # надо дать шанс защититься, если регион пренадлежал расе не в упадке
      return ABORT if $ans->{result} eq R_ALL_OK && $needDefend;
      # состояние игры изменилось на conquest, поэтому продолжаем воевать
      $res = CONQUERED;
      $repeat = 1; # надо повторить, вдруг сможем ещё что-то захватить
    }
  } while ( $repeat );
  return $res;
}

sub _decline {
  my ($self, $g) = @_;
  die 'Fail decline' if
    $self->_sendGameCmd(game => $g, action => 'decline')->{result} ne R_ALL_OK;
  $g->{gs}->decline();
}

sub _finishTurn {
  my ($self, $g) = @_;
  $self->_sendGameCmd(game => $g, action => 'finishTurn');
  $g->{gs}->finishTurn({});
}

sub _redeploy {
  my ($self, $g) = @_;
  $g->{gs}->gotoRedeploy();
  my $p = $g->{gs}->getPlayer();
  my $tokens = $p->tokens;
  my $regs = $p->activeRace()->regions;
  my $n = scalar(@$regs);
  my @regions = ();
  my @heroes = ();
  my @encampments = ();
  my %fortified = ();

  if ( $n == 0 ) {
    # если мы попали в redeploy и у нас нет регионов, то значит на сервере
    # воссоздалась ошибочная ситуация (когда нет регионов, которые мы могли бы
    # захватить (т. е. все возможные под иммунитетом) и нас заставляют захватывать.
    # Единственное, что мы можем сделать, так это redeploy. Но и его мы не можем
    # сделать, т. к. нельзя делать redeploy, когда нет регионов.
    # Значит признаём возможное поражение и покидаем игру.
    $self->_leaveGame($g);
    return;
  }

  # прежде, чем мы начнем расставлять фигурки, надо зарезервировать одну фигурку
  # за регионом, который мы захватили драконом, а также подсчитать общее
  # количество фигурок
  foreach ( @$regs ) {
    my $r = $g->{gs}->getRegion($_->{regionId});
    if ( $r->dragon ) {
      push @regions, { regionId => $r->id, tokensNum => 1 };
      $n -= 1;
    }
    else {
      $tokens += $r->tokens;
    }
  }

  if ( $self->_canPlaceHero($g) ) {
    # обнуляем всех ранее расставленных героев
    $_->{hero} = 0 for @$regs;
    my $i = 0; # счетчик героев
    foreach ( @$regs ) {
      my $r = $g->{gs}->getRegion($_->{regionId});
      $r->hero(1);
      $r->tokens(1);
      $tokens -= 1;
      $n -= 1;
      push @heroes, { regionId => $r->id };
      # вместе с героем мы обязаны поставить хотя бы одну фигурку
      push @regions, { regionId => $r->id, tokensNum => 1 };
      last if ++$i >= HEROES_MAX;
    }
  }

  if ( $self->_canPlaceEncampment($g) ) {
    # прежде, чем мы начнем ставить лагеря, надо посчитать сколько максмимум мы
    # можем поставить
    my $encampNum = ENCAMPMENTS_MAX;
    # надо пробежаться по всем НЕ нашим регионам и вычесть количество уже
    # расставленных лагерей, которые мы не можем двигать
    $encampNum -= $self->_alienEncampNum($g);
    # каждый лагерь, который мы сейчас будем расставлять приравнивается одной
    # фигурке
    $tokens += $encampNum;
    # обнуляем все наши предыдущие расстановки лагерей
    $_->{encampment} = 0 for @$regs;
    # стараемся равномерно разместить лагеря по всем нашим регионам
    my $delta = max(1, int($encampNum / $n));
    my $r = undef;
    foreach ( @$regs ) {
      $r = $g->{gs}->getRegion($_->{regionId});
      my $num = $delta;
      $encampNum -= $num;
      if ( $encampNum < 0 ) {
        $num += $encampNum;
        $encampNum = 0;
      }
      $r->encampment($num);
      push @encampments, { regionId => $r->id, encampmentsNum => $num };
      last if $encampNum == 0;
    }
    if ( $encampNum != 0 ) {
      $encampments[-1]->{encampmentsNum} += $encampNum;
      $r->encampment($r->encampment + $encampNum);
    }
  }

  if ( $self->_canPlaceFortified($g) ) {
    foreach ( @$regs ) {
      my $r = $g->{gs}->getRegion($_->{regionId});
      $tokens += 1;
      if ( !$r->fortified ) {
        $r->fortified(1);
        $fortified{regionId} = $_->{regionId};
        last; # за один ход можно ставить только одно укрепление
      }
    }
  }

  if ( $n != 0 ) {
    # если у нас остались регионы, на которых не расположились герои и дракон
    # (т. е. есть регионы без иммунитета), то распологаем фигурки равномерно
    # в этих оставшихся регионах
    my $delta = max(1, int($tokens / $n));
    foreach ( @$regs ) {
      my $r = $g->{gs}->getRegion($_->{regionId});
      next if $r->hero || $r->dragon;

      my $num = $delta;
      $tokens -= $num;
      $num -= $r->encampment;
      $num -= $r->fortified;

      if ( $tokens < 0  ) {
        $num += $tokens;
        $tokens = 0;
      }
      $r->tokens($num);
      push @regions, { regionId => $_->{regionId}, tokensNum => $num };
      last if $tokens == 0;
    }
  }
  if ( $tokens != 0 ) {
    $regions[-1]->{tokensNum} += $tokens;
    my $r = $g->{gs}->getRegion($regions[-1]->{regionId});
    $r->tokens($r->tokens + $tokens);
  }
  $p->tokens(0);
  $self->_sendGameCmd(
      game        => $g,
      action      => 'redeploy',
      regions     => \@regions,
      encampments => (@encampments ? \@encampments : undef),
      heroes      => (@heroes ? \@heroes : undef),
      fortified   => (%fortified ? \%fortified : undef));
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
  my $p = min(int(rand(6)), $g->{gs}->getPlayer()->coins);
  die 'Fail select race' if
    $self->_sendGameCmd(game => $g, action => 'selectRace', position => $p)->{result} ne R_ALL_OK;
}

sub _cmd_beforeConquest {
  my ($self, $g) = @_;
  my $res = $self->_conquer($g);
  return if $res == ABORT;
  # размещаем войска
  return $self->_redeploy($g) if $res == CONQUERED;
  # у нас ничего не получилось завоевать и состояние игры не изменилось, значит
  # расу в упадок, ибо УГ
  $self->_decline($g);
}

sub _cmd_conquest {
  my ($self, $g, $i) = (@_, 0);
  my $res = $self->_conquer($g);
  return if $res == ABORT;
  # размещаем войска
  $self->_redeploy($g);
}

sub _cmd_redeploy {
  my ($self, $g) = @_;
  $self->_redeploy($g);
}

sub _cmd_beforeFinishTurn {
  my ($self, $g) = @_;
  if ( $self->_canStoutDecline($g) && $self->_needStoutDecline($g) ) {
    $self->_decline($g);
  }
  if ( $self->_canSelectFriend($g) ) {
    foreach ( @{ $g->{gs}->players } ) {
      if ( $self->_canSelectFriend($g, $_->{playerId}) ) {
        die 'Fail select friend' if
          $self->_sendGameCmd(game => $g, action => 'selectFriend', friendId => $_->{playerId})->{result} ne R_ALL_OK;
        last;
      }
    }
  }
  $self->_finishTurn($g);
}

sub _cmd_finishTurn {
  my ($self, $g) = @_;
  $self->_finishTurn($g);
}

sub games { return $_[0]->{games}; }

1;

__END__
