package AI::Player;


use strict;
use warnings;
use utf8;

use JSON qw( decode_json encode_json );
use List::Util qw( max min );

use SmallWorld::Checker qw(
    checkRegion_conquer
    checkRegion_defend
    checkRegion_enchant
    checkFriend
);
use SmallWorld::Consts;
use SmallWorld::Game;
use SW::Util qw( swLog timeStart timeEnd );

use AI::Config;
use AI::Consts;
use AI::DB;
use AI::Output qw( printGames printDebug );


our @savedRegionFields = qw( conquestIdx prevTokensNum prevTokenBadgeId _cavernAdj _type );


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
    $self->games->{$p{game}}->{ais} = eval { decode_json($p{ais}) } || [];
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
  my ($self, $g, $playerId) = @_;
  $g->{gs}->dropObjects();
  my $state = { };
  $self->_saveState($g, $state);
  $state = encode_json($state);
  my $where = { playerId => $playerId };
  if ( $self->{db}->select1(from => STATES_TABLE, fields => [ 1 ], where => $where) ) {
    $self->{db}->update(update => STATES_TABLE, set => { state => $state }, where  => $where);
  }
  else {
    $self->{db}->insert(into => STATES_TABLE, values => { %$where, state => $state });
  }
}

sub _saveState {
  my ($self, $g, $state) = @_;
  $state->{regions} = [];
  foreach my $r ( @{ $g->{gs}->regions } ) {
    my $s = {};
    # сохраняем в БД информацию, которая генерируется во время завоевания
    for ( ('regionId', @savedRegionFields) ) {
      $s->{$_} = $r->{$_} if defined $r->{$_};
    }
    push @{ $state->{regions} }, $s;
  };
}

sub _load {
  my ($self, $g, $playerId) = @_;
  my $state = $self->{db}->select1(
      from   => STATES_TABLE,
      fields => ['state'],
      where  => { playerId => $playerId });
  return if !defined $state;
  $state = decode_json($state);
  timeStart();
  $self->_loadState($g, $state);
  timeEnd(LOG_FILE, '_loadState ');
}

sub _loadState {
  my ($self, $g, $state) = @_;
  foreach my $s ( @{ $state->{regions} // [] } ) {
    my $r = $g->{gs}->getRegion(id => $s->{regionId});
    # загружаем из БД информацию, которая нужна, что корректно предсказывать
    # результат хода
    foreach ( @savedRegionFields ) {
      $r->{$_} = $s->{$_} if defined $s->{$_};
    }
    $r->buildAdjacents();
  }
}

sub do {
  my ($self, $game) = @_;
  if ( $game->{state} == GST_WAIT && $game->{aiRequiredNum} > 0 ) {
    # если игра в режиме ожидания игроков, то пытаемся к ней подключиться
    $self->_join2Game($game);
    return;
  }

  if ( $game->{state} == GST_FINISH ) {
    # если игра закончилась и мы в ней играли, то покидаем эту игру
    $self->_allLeaveGame($game);
  }

  if ( $self->_ourTurn($game) ) {
    # если сейчас наш ход, то играем
    $self->_play($game);
    return;
  }
}

# выводит информацию о играх в консоль
sub printStatus {
  my $self = shift;
  printGames($self->games);
}

# присоединяемся к игре
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
  swLog(LOG_FILE, $g, $r);
}

# все ИИ покидают игру
sub _allLeaveGame {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  foreach ( @{ $g->{ais} // [] } ) {
    $self->_leaveGame($g, $_->{sid});
  }
}

# проверяет наш сейчас ход или нет
sub _ourTurn {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  return 0 if !defined $g; # мы даже не присоединялись к этой игре

  my $r = $self->_get('{ "action": "getGameState", "gameId": ' . $game->{gameId} . ' }', 1);
  return 0 if $r->{result} ne R_ALL_OK; # не получилось обновить состояние игры

  timeStart();
  $g->{gs} = SmallWorld::Game->new(gameState => $r->{gameState});
  timeEnd(LOG_FILE, 'SmallWorld::Game->new ');
  return (grep { $_->{id} == ($g->{gs}->activePlayerId // -1) } @{ $g->{ais} });
}

# играет ИИ
sub _play {
  my ($self, $game) = @_;
  my $g = $self->games->{$game->{gameId}};
  my $playerId = $g->{gs}->activePlayerId; # запомним id активного игрока, потому что он может поменяться
  $self->_load($g, $playerId);
  my $func = $self->can("_cmd_" . $g->{gs}->stage);
  &$func($self, $g) if defined $func;
  $self->_save($g, $playerId);
}

# посылает команду на сервер от имени активного игрока
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
  die "Can't define sid of player for command $cmd->{action}\n" if !defined $cmd->{sid};
  (!defined $cmd->{$_} and delete $cmd->{$_}) for keys %$cmd;
  $cmd = eval { encode_json($cmd) } || die "Can't encode json :(\n";
  $self->_get($cmd, 1);
}

# текущий ход последний?
sub _isLastTurn {
  my ($self, $g) = @_;
  return $g->{gs}->currentTurn == $g->{gs}->maxTurnNum;
}

# используем способность для завоевания региона
sub _useSpConquer {
  my ($self, $g, $regionId, $ans) = @_;
  if ( $self->_canEnchant($g, $regionId) ) {
    $$ans = $self->_sendGameCmd(game => $g, action => 'enchant', regionId => $regionId);
    die "Fail enchant" if $$ans->{result} ne R_ALL_OK;
    $g->{gs}->enchant($regionId);
    return 1;
  }
  if ( $self->_canDragonAttack($g, $regionId) && $self->_shouldDragonAttack($g, $regionId) ) {
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

# количество лагерей, которые стоят на чужих регионах
sub _alienEncampNum {
  my ($self, $g) = @_;
  my $result = 0;
  foreach ( @{ $g->{gs}->regions } ) {
    $result += ($_->{encampment} // 0) if ($_->{ownerId} // -1) != $g->{gs}->activePlayerId;
  }
  return $result;
}

# можем ли мы произвести атаку по базовым правилам
sub _canBaseAttack {
  my ($self, $g, $regionId) = @_;
  my $r = $g->{gs}->getRegion(id => $regionId);
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return !$r->isImmune() && $p->tokens > 0 &&
    !$self->checkRegion_conquer(undef, $g->{gs}, $p, $r, $ar, $asp, undef);
}

# стоит ли нам пытаться захватить регион фигурками
sub _canAttack {
  my ($self, $g, $regionId) = @_;
  my $r = $g->{gs}->getRegion(id => $regionId);
  my $p = $g->{gs}->getPlayer();
  my $dummy = {
    dice => defined $g->{gs}->berserkDice ? 0 : 3, # максимум возможное # TODO: переделать
    readOnly => 1
  };
  my $ar = $p->activeRace();
  my $asp = $p->activeSp();
  return $self->_canBaseAttack($g, $regionId) && $g->{gs}->canAttack($p, $r, $ar, $asp, $dummy);
}

# можем ли мы зачаровать этот регион
sub _canEnchant {
  my ($self, $g, $regionId) = @_;
  my $ar = $g->{gs}->getPlayer->activeRace;
  my $canCmd = $ar->canCmd('enchant', $g->{gs}->{gameState});
  return $canCmd if !defined $regionId || !$canCmd;

  my $r = $g->{gs}->getRegion(id => $regionId);
  return
    $self->_canBaseAttack($g, $regionId) &&
    $self->_canEnchantOnlyRules($g, $r);
}

# можем ли мы зачаровать этот регион (проверяются только правила зачарования)
sub _canEnchantOnlyRules {
  my ($self, $g, $r) = @_;
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace;
  my $asp = $p->activeSp;
  return !$self->checkRegion_enchant(undef, $g->{gs}, $p, $r, $ar, $asp, undef);
}

# можем ли мы атаковать драконом регион
sub _canDragonAttack {
  my ($self, $g, $regionId) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return (!defined $regionId || $self->_canBaseAttack($g, $regionId)) &&
    $asp->canCmd({ action => 'dragonAttack' }, $g->{gs}->stage, $p);
}

# можем ли мы бросить кости берсерка
sub _canThrowDice {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'throwDice' }, $g->{gs}->stage, $p);
}

# можем ли мы привести расу в упадок способностью Stout
sub _canStoutDecline {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp();
  return $asp->canCmd({ action => 'decline' }, $g->{gs}->stage, $p);
}

# можем ли мы выбрать игрока в качестве друга
# если игрок не задан, то имеем ли мы чисто теоретически такую возможность
sub _canSelectFriend {
  my ($self, $g, $playerId) = (@_, 0);
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  my $js = { action => 'selectFriend', friendId => $playerId };
  my $can = $asp->canCmd($js, $g->{gs}->stage, $p);
  return $can if !$can || $playerId == 0;
  return !$self->checkFriend($js, $g->{gs}, $p);
}

# можем ли мы размещать героев
sub _canPlaceHero {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'redeploy', heroes => [] }, $g->{gs}->stage, $p);
}

# можем мы ли размещать лагеря
sub _canPlaceEncampment {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'redeploy', encampments => [] }, $g->{gs}->stage, $p) &&
    $self->_alienEncampNum($g) < ENCAMPMENTS_MAX;
}

# можем ли мы размещать форты
sub _canPlaceFortified {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $asp = $p->activeSp;
  return $asp->canCmd({ action => 'redeploy', fortified => {} }, $g->{gs}->stage, $p) &&
    scalar(grep $_->{fortified}, @{ $g->{gs}->regions }) < FORTRESS_MAX;
}

# можем ли мы защититься "в этот регион"
sub _canDefendToRegion {
  my ($self, $g, $regionId, $p, $ar) = @_;
  return !$self->checkRegion_defend({ regions => [{ regionId => $regionId }] },
      $g->{gs}, $p, undef, $ar, undef, {});
}

# следует ли нам применить способность Stout и привести расу в упадок
sub _shouldStoutDecline {
  # TODO: наверное, это уже будет продвинутый ИИ, если он будет решать нужно ли
  # ему приводить расу в упадок способностью Stout
  return !int(rand(5));
}

# следует ли нам напасть на этот регион драконом
sub _shouldDragonAttack {
  my ($self, $g, $regionId) = @_;
  # простой ИИ при первой же возможности пользуется атакой дракона
  return 1;
}

# следует ли нам зачаровать этот регион
sub _shouldEnchant {
  my ($self, $g, $regionId) = @_;
  # простой ИИ при первой же возможности пользуется зачарованием
  return 1;
}

# следует ли нам выбрать данного игрока в друзья
sub _shouldSelectFriend {
  my ($self, $g, $playerId) = @_;
  return $self->_canSelectFriend($g, $playerId);
}

# возвращает список регионов, на которые мы должны напасть
sub _getRegionsForConquest {
  my ($self, $g) = @_;
  return @{ $g->{gs}->regions };
}

# возвращает размещение войск по регионам для команды redeploy
sub _getRedeployment {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $tokens = $p->tokens;
  my $regs = $p->activeRace()->regions;
  my $n = scalar(@$regs);
  my @regions = ();
  my @heroes = ();
  my @encampments = ();
  my %fortified = ();

  # прежде, чем мы начнем расставлять фигурки, надо зарезервировать одну фигурку
  # за регионом, который мы захватили драконом, а также подсчитать общее
  # количество фигурок
  foreach ( @$regs ) {
    if ( $_->dragon ) {
      push @regions, { regionId => $_->id, tokensNum => 1 };
      $n -= 1;
    }
    else {
      $tokens += $_->tokens;
    }
  }

  if ( $self->_canPlaceHero($g) ) {
    # обнуляем всех ранее расставленных героев
    $_->{hero} = 0 for @$regs;
    my $i = 0; # счетчик героев
    foreach ( @$regs ) {
      $_->hero(1);
      $_->tokens(1);
      $tokens -= 1;
      $n -= 1;
      push @heroes, { regionId => $_->id };
      # вместе с героем мы обязаны поставить хотя бы одну фигурку
      push @regions, { regionId => $_->id, tokensNum => 1 };
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
    my $m = $n;
    my $r = undef;
    foreach ( @$regs ) {
      my $num = max(1, int($encampNum / $m));
      $m -= 1;
      $encampNum -= $num;
      if ( $encampNum < 0 ) {
        $num += $encampNum;
        $encampNum = 0;
      }
      $_->encampment($num);
      push @encampments, { regionId => $_->id, encampmentsNum => $num };
      last if $encampNum == 0;
    }
    if ( $encampNum != 0 ) {
      $encampments[-1]->{encampmentsNum} += $encampNum;
      $_->encampment($_->encampment + $encampNum);
    }
  }

  if ( $self->_canPlaceFortified($g) ) {
    foreach ( @$regs ) {
      $tokens += 1;
      if ( !$_->fortified ) {
        $_->fortified(1);
        $fortified{regionId} = $_->id;
        last; # за один ход можно ставить только одно укрепление
      }
    }
  }

  if ( $n != 0 ) {
    # если у нас остались регионы, на которых не расположились герои и дракон
    # (т. е. есть регионы без иммунитета), то распологаем фигурки равномерно
    # в этих оставшихся регионах
    foreach ( @$regs ) {
      next if $_->hero || $_->dragon;

      my $num = max(1, int($tokens / $n));
      $n -= 1;
      $tokens -= $num;
      $num -= $_->encampment;
      $num -= $_->fortified;

      if ( $tokens < 0  ) {
        $num += $tokens;
        $tokens = 0;
      }
      $_->tokens($num);
      push @regions, { regionId => $_->id, tokensNum => $num };
      last if $tokens == 0;
    }
  }
  if ( $tokens != 0 ) {
    $regions[-1]->{tokensNum} += $tokens;
    my $r = $g->{gs}->getRegion(id => $regions[-1]->{regionId});
    $r->tokens($r->tokens + $tokens);
  }
  $p->tokens(0);

  return (
      regions     => \@regions,
      encampments => (@encampments ? \@encampments : undef),
      heroes      => (@heroes ? \@heroes : undef),
      fortified   => (%fortified ? \%fortified : undef));
}

sub _beginConquest { }

sub _beginTurn { }

sub _endConquest { }

# пытаемся захватить конкретный регион
sub _conquerRegion {
  my ($self, $g, $regionId) = @_;
  my $ans = {};
  return 1 if $self->_useSpConquer($g, $regionId, \$ans);
  return 0 if !$self->_canAttack($g, $regionId);
  $ans = $self->_sendGameCmd(game => $g, action => 'conquer', regionId => $regionId);
  if ( defined $ans->{dice} ) {
    my $p = $g->{gs}->getPlayer();
    # изменяем все состояние согласно правилам
    $g->{gs}->canAttack($p, $g->{gs}->getRegion(id => $regionId), $p->activeRace, $p->activeSp, $ans);
  }
  if ( $ans->{result} eq R_ALL_OK ) {
    # изменяем все состояние согласно правилам
    $g->{gs}->conquer($regionId, {});
    return 1;
  }
  return 0;
}

# покидаем игру
sub _leaveGame {
  my ($self, $g, $sid) = @_;
  swLog(LOG_FILE, "try leaveGame sid=$sid");
  $self->_sendGameCmd(game => $g, action => 'leaveGame', sid => $sid);
  if ( !defined $sid ) {
    for ( @{ $g->{ais} } ) {
      $sid = $_->{sid};
      last if $_->{id} == $g->{gs}->activePlayerId;
    }
  }
  $g->{ais} = [grep $_->{sid} != $sid, @{ $g->{ais} }];
  swLog(LOG_FILE, 'leaveGame', $g->{ais}, $sid);
}

# производим захват регионов
sub _conquer {
  my ($self, $g) = @_;
  my $repeat = 0;
  do {
    $self->_beginConquest($g);
    $repeat = 0;
    foreach ( $self->_getRegionsForConquest($g) ) {
      my $conq = $self->_conquerRegion($g, $_->{regionId});
      $repeat = $repeat || $conq; # надо повторить, вдруг сможем ещё что-то захватить
      return if $g->{gs}->stage ne GS_CONQUEST && $g->{gs}->stage ne GS_BEFORE_CONQUEST;
    }
    $self->_endConquest($g);
  } while ( $repeat );
}

# приводим расу в упадок
sub _decline {
  my ($self, $g) = @_;
  die 'Fail decline' if
    $self->_sendGameCmd(game => $g, action => 'decline')->{result} ne R_ALL_OK;
  $g->{gs}->decline();
}

# заканчиваем ход
sub _finishTurn {
  my ($self, $g) = @_;
  $self->_sendGameCmd(game => $g, action => 'finishTurn');
  $g->{gs}->finishTurn({});
}

# делаем перестановку войск
sub _redeploy {
  my ($self, $g) = @_;

  if ( scalar(@{ $g->{gs}->getPlayer->activeRace->regions }) == 0 ) {
    # если мы попали в redeploy и у нас нет регионов, то значит на сервере
    # воссоздалась ошибочная ситуация (когда нет регионов, которые мы могли бы
    # захватить (т. е. все возможные под иммунитетом) и нас заставляют захватывать.
    # Единственное, что мы можем сделать, так это redeploy. Но и его мы не можем
    # сделать, т. к. нельзя делать redeploy, когда нет регионов.
    # Значит признаём возможное поражение и покидаем игру.
    $self->_leaveGame($g);
    return;
  }

  $g->{gs}->gotoRedeploy();
  die 'Fail redeploy' if $self->_sendGameCmd(
      game        => $g,
      action      => 'redeploy',
      $self->_getRedeployment($g))->{result} ne R_ALL_OK;
}

# выбираем расу
sub _selectRace {
  my ($self, $g) = @_;
  return min(int(rand(6)), $g->{gs}->getPlayer()->coins);
}

# действия перед тем как закончить ход
sub _beforeFinishTurn {
  my ($self, $g) = @_;
  if ( $self->_canStoutDecline($g) && $self->_shouldStoutDecline($g) ) {
    $self->_decline($g);
  }
  if ( $self->_canSelectFriend($g) ) {
    foreach ( @{ $g->{gs}->players } ) {
      if ( $self->_shouldSelectFriend($g, $_->{playerId}) ) {
        die 'Fail select friend' if
          $self->_sendGameCmd(game => $g, action => 'selectFriend', friendId => $_->{playerId})->{result} ne R_ALL_OK;
        last;
      }
    }
  }
  $self->_finishTurn($g);
}

# защищаемся. Возвращает массив хешей (regionId, tokensNum)
sub _defend {
  my ($self, $g) = @_;
  my $p = $g->{gs}->getPlayer();
  my $ar = $p->activeRace;
  foreach ( @{ $ar->regions } ) {
    next unless $self->_canDefendToRegion($g, $_->{regionId}, $p, $ar);
    return [ { regionId => $_->{regionId}, tokensNum => $p->tokens } ];
  }
  die "Can't find region for defend";
}

################################################################################
#           методы, которые срабатывают на различные состояния игры            #
################################################################################

sub _cmd_defend {
  my ($self, $g) = @_;
  die "Fail defend" if $self->_sendGameCmd(
      game => $g,
      action => 'defend',
      regions => $self->_defend($g)
  )->{result} ne R_ALL_OK;
  $_->{conquestIdx} = undef for @{ $g->{gs}->regions };
}

sub _cmd_selectRace {
  my ($self, $g) = @_;
  $self->_beginTurn($g);
  die 'Fail select race' if
    $self->_sendGameCmd(game => $g, action => 'selectRace', position => $self->_selectRace($g))->{result} ne R_ALL_OK;
}

sub _cmd_beforeConquest {
  my ($self, $g) = @_;
  $self->_beginTurn($g);
  $self->_conquer($g);
  # надо прервать все наши действия, что бы дать другому игроку защититься, если
  # в этом есть необходимость
  return if $g->{gs}->stage eq GS_DEFEND;
  # выполняем последние действия за ход, если соответствующее состояние игры
  return $self->_beforeFinishTurn($g) if $g->{gs}->stage eq GS_BEFORE_FINISH_TURN;
  # размещаем войска
  return $self->_redeploy($g) if $g->{gs}->stage ne GS_BEFORE_CONQUEST;
  # у нас ничего не получилось завоевать и состояние игры не изменилось, значит
  # расу в упадок, ибо УГ
  $self->_decline($g);
}

sub _cmd_conquest {
  my ($self, $g, $i) = (@_, 0);
  $self->_conquer($g);
  # размещаем войска
  $self->_redeploy($g) if $g->{gs}->stage eq GS_CONQUEST || $g->{gs}->stage eq GS_REDEPLOY;
}

sub _cmd_redeploy {
  my ($self, $g) = @_;
  $self->_redeploy($g);
}

sub _cmd_beforeFinishTurn {
  my ($self, $g) = @_;
  $self->_beforeFinishTurn($g);
}

sub _cmd_finishTurn {
  my ($self, $g) = @_;
  $self->_finishTurn($g);
}

sub games { return $_[0]->{games}; }

1;

__END__
