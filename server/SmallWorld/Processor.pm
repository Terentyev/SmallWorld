package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON qw(encode_json decode_json);

use Scalar::Util;
use SmallWorld::Consts;
use SmallWorld::Config;
use SmallWorld::DB;

sub new {
  my $class = shift;
  my $self = { json => undef, db => undef };
  my ($r) = @_;
  if ( !$r ) {
    $r = '{}';
  }
  $self->{json} = eval { return decode_json($r) or {}; };
  $self->{db} = SmallWorld::DB->new;

  bless $self, $class;
  return $self;
}

sub process {
  my ($self) = @_;
  $self->{db}->connect(DB_NAME, DB_LOGIN, DB_PASSWORD, DB_MAX_BLOB_SIZE);

  my $result = { result => $self->checkJsonCmd() };

  if ( $result->{result} eq R_ALL_OK ) {
    my $cmd = $self->{json}->{action};
    my $func = \&{"cmd_$cmd"};
    &$func($self, $result);
  }
  $self->{db}->disconnect;
  print encode_json($result)."\n" or die "Can not encode JSON-object\n";
}

sub debug {
  return if !$ENV{DEBUG};
  use Data::Dumper; print Dumper(@_);
}

sub checkLoginAndPassword {
  my $self = shift;
  return !defined $self->{db}->query('SELECT 1 FROM PLAYERS WHERE username = ? and pass = ?',
                                     @{$self->{json}}{qw/username password/} );
}

sub checkInGame {
  my $self = shift;
  my $gameId = $self->{db}->query('SELECT gameId FROM PLAYERS WHERE sid = ?', $self->{json}->{sid});
  return defined $gameId;
}

sub checkPlayersNum {
  my $self = shift;
  my $n = $self->{db}->getMaxPlayers($self->{json}->{gameId});
  return $self->{db}->playersCount($self->{json}->{gameId}) >= $n;
}

sub checkIsStarted {
  my ($self, $h) = @_;
  my $gameId = exists($h->{gameId}) ? $h->{gameId} : $self->{db}->getGameId($h->{sid});
  $self->{db}->getGameState($gameId);
}

sub checkRegions {
  my $self = shift;
  my $s = 0;
  my $r = $self->{json}->{regions};
  my $l = @$r;
  my $ex;
  for (my $i = 0; $i < $l; ++$i){
    $s += @$r[$i]->{population} if exists @$r[$i]->{population};

    foreach my $j (@{@$r[$i]->{landDescription}}) {
      $ex = 0;
      foreach (@{&REGION_TYPES}) {
        if ($_ eq $j) {
          $ex = 1;
          last;
        }
      }
      return 1 if !$ex;
    }
    return 1 if ref @$r[$i]->{adjacent} ne 'ARRAY';
    foreach my $j (@{@$r[$i]->{adjacent}}) {
      #регион граничет с недопустимым регионом или самим собой
      return 1 if $j< 1 || $j > $l || $j == $i + 1;

      #регион A граничет с регионом B, а регион B не граничет с A
      $ex = 0;
      foreach (@{@$r[$j-1]->{adjacent}}) {
        if ($_ == $i + 1) {
          $ex = 1;
          last;
        }
      }
      return 1 if !$ex;
    }
  }
  return $s > LOSTTRIBES_TOKENS_MAX;
}

sub checkJsonCmd {
  my ($self) = @_;
  my $json = $self->{json};
  my $cmd = $json->{action};
  return R_BAD_JSON if !defined $cmd;

  my $pattern = PATTERN->{$cmd};
  return R_BAD_ACTION if !$pattern;
  foreach ( @$pattern ) {
    my $val = $json->{ $_->{name} };
    # если это необязательное поле и оно пустое, то пропускаем его
    if ( !$_->{mandatory} && !defined $val ) {
      next;
    }

    # если это обязательное поле и оно пустое, то ошибка
    return $self->errorCode($_) if ( !defined $val );

    # если тип параметра -- строка
    if ( $_->{type} eq 'unicode' ) {
      # если длина строки не удовлетворяет требованиям, то ошибка
      return $self->errorCode($_) if ref(\$val) ne 'SCALAR';
      if ( defined $_->{min} && length $val < $_->{min} ||
          defined $_->{max} && length $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
    elsif ( $_->{type} eq 'int' ) {
      # если число, передаваемое в параметре не удовлетворяет требованиям, то ошибка
      return $self->errorCode($_) if ref(\$val) ne 'SCALAR' || $val !~ /^[+-]?\d+\z/;
      if ( defined $_->{min} && $val < $_->{min} ||
          defined $_->{max} && $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
    elsif ( $_->{type} eq 'list' ) {
      return $self->errorCode($_) if ref($val) ne 'ARRAY';
    }

  }

  my $errorHandlers = {
    &R_ALREADY_IN_GAME  => sub { $self->checkInGame(); },
    &R_BAD_GAME_ID      => sub { !$self->{db}->dbExists('games', 'id', $self->{json}->{gameId}); },
    &R_BAD_GAME_NAME    => sub { $self->{db}->dbExists('games', 'name', $self->{json}->{gameName}); },
    &R_BAD_GAME_STATE   => sub { $self->checkIsStarted($self->{json}); },
    &R_BAD_LOGIN        => sub { $self->checkLoginAndPassword(); },
    &R_BAD_MAP_ID       => sub { !$self->{db}->dbExists('maps', 'id', $self->{json}->{mapId}); },
    &R_BAD_MAP_NAME     => sub { $self->{db}->dbExists('maps', 'name', $self->{json}->{mapName}); },
    &R_BAD_PASSWORD     => sub { $self->{json}->{password} !~ m/^.{6,18}$/;},
    &R_BAD_REGIONS      => sub { $self->checkRegions();},
    &R_BAD_SID          => sub { defined $self->{json}->{sid} && !$self->{db}->dbExists('players', 'sid', $self->{json}->{sid}); },
    &R_BAD_USERNAME     => sub { $self->{json}->{username} !~ m/^[A-Za-z][\w\-]*$/;},
    &R_NOT_IN_GAME      => sub { !defined $self->{db}->getGameId($self->{json}->{sid}); },
    &R_TOO_MANY_PLAYERS => sub { $self->checkPlayersNum(); },
    &R_USERNAME_TAKEN   => sub { $self->{db}->dbExists('players', 'username', $self->{json}->{username});}
  };

  my $errorList = CMD_ERRORS->{$cmd};
  foreach ( @$errorList ) {
    return $_ if $errorHandlers->{$_}->();
  }

  return R_ALL_OK;
}

sub errorCode() {
  my ($self, $paramInfo) = @_;
  return $paramInfo->{errorCode} || R_BAD_JSON;
}

# Команды, которые приходят от клиента
sub cmd_resetServer {
  my ($self, $result) = @_;
  $self->{db}->clear();
}

sub cmd_register {
  my ($self, $result) = @_;
  $self->{db}->addPlayer( @{$self->{json}}{qw/username password/} );
}

sub cmd_login {
  my ($self, $result) = @_;
  $result->{sid} = $self->{db}->makeSid( @{$self->{json}}{qw/username password/} );
}

sub cmd_logout {
  my ($self, $result) = @_;
  $self->{db}->logout($self->{json}->{sid});
}

sub cmd_sendMessage {
  my ($self, $result) = @_;
  $self->{db}->addMessage( @{$self->{json}}{qw/sid text/} );
}

sub cmd_getMessages {
  my ($self, $result) = @_;
  my $ref = $self->{db}->getMessages($self->{json}->{since});
  my @a = ();
  my $n = @$ref;
  for (my $i = 0; $i < $n; $i += 4){
    push @a, { 'id' => @$ref[$i], 'text' => @$ref[$i+1], 'userId' => @$ref[$i+2], 'time' => TEST_MODE ? @$ref[$i] : @$ref[$i+3] };
  }
  @{$result->{messages}} = reverse @a;
}

sub cmd_createDefaultMaps {
  my ($self, $result) = @_;
  foreach (@{&DEFAULT_MAPS}){
    $self->{db}->addMap( @{$_}{ qw/mapName playersNum turnsNum/}, exists($_->{regions}) ? encode_json($_->{regions}) : "[]");
  }
}

sub cmd_uploadMap {
  my ($self, $result) = @_;
  $result->{mapId} = $self->{db}->addMap( @{$self->{json}}{qw/mapName playersNum turnsNum regions/} );
}

sub cmd_createGame {
  my ($self, $result) = @_;
  $result->{gameId} = $self->{db}->createGame( @{$self->{json}}{qw/sid gameName mapId gameDescr/} );
}


sub cmd_getGameList {
  my ($self, $result) = @_;
  my $ref = $self->{db}->getGames();
  $result->{games} = [];
  foreach my $row ( @{$ref} ) {
    push @{$result->{games}}, { 'gameId' => $row->{ID}, 'gameName' => $row->{NAME}, 'gameDescription' => $row->{DESCRIPTION},
                                'mapId' => $row->{MAPID}, 'state' => $row->{ISSTARTED} + 1};
   # добавить "state" после уточнений
    my $pl = $self->{db}->getPlayers($row->{ID});
    my @players = ();
    foreach ( @{$pl} ) {
      push @players, { 'userId' => $_->{ID}, 'userName' => $_->{USERNAME}, 'isReady' => $_->{ISREADY} };
    }
    push @{$result->{games}}, { 'players' => \@players };
  }
}

sub cmd_getMapList {
  my ($self, $result) = @_;
  my $ref = $self->{db}->getMaps();
  $result->{maps} = ();
  my $n = @$ref;
  for (my $i = 0; $i < $n; $i += 4){
    push @{$result->{maps}}, { 'mapId' => @$ref[$i], 'mapName' => @$ref[$i+1], 'playersNum' => @$ref[$i+2], 'turnsNum' => @$ref[$i+3] };
  }
}

sub cmd_joinGame {
  my ($self, $result) = @_;
  $self->{db}->joinGame( @{$self->{json}}{qw/gameId sid/} );
}

sub cmd_leaveGame {
  my ($self, $result) = @_;
  $self->{db}->leaveGame($self->{json}->{sid});
}

sub cmd_setReadinessStatus {
  my ($self, $result) = @_;
  $self->{db}->setIsReady( @{$self->{json}}{qw/isReady sid/} );
  #TO DO
  $self->{json}->{visibleRaces};
  $self->{json}->{visiblePowers};
}

sub cmd_selectRace {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{position};
}

sub cmd_conquer {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{regionId};
  $self->{json}->{raceId};
}

sub cmd_decline {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_finishTurn {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_doSmtn {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_redeploy {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{raceId};
  $self->{json}->{regions};
}

sub cmd_defend {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{regions};
}

sub cmd_enchant {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{regionId};
}

sub cmd_getVisibleTokenBadges {
  my ($self, $result) = @_;
  $self->{json}->{gameId};
}

sub cmd_throwDice {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{dice};
}

1;

__END__
