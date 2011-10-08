package SmallWorld::Processor;


use strict;
use warnings;
use utf8;

use JSON qw(encode_json decode_json);

use SmallWorld::Consts;
use SmallWorld::Conf;
use SmallWorld::DB;

sub new {
  my $class = shift;
  my $self = { json => undef, db => undef };
  my ($r) = @_;
  if ( !$r ) {
    $r = "{}";
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
  print encode_json($result) or die "Can not encode JSON-object\n";
}

sub debug {
  return if !$ENV{DEBUG};
  use Data::Dumper; print Dumper(@_);
}

sub checkUsername {
  return R_ALREADY_TAKEN if $_[0]->{db}->dbExists("players", "username", $_[0]->{json}->{username});   
  return 0;
}

sub checkPassword {
  return 0;
}


sub checkJsonCmd {
  my ($self) = @_;
  my $json = $self->{json};
  my $cmd = $json->{action};
  return R_BAD_JSON if !$cmd;

  my $pattern = PATTERN->{$cmd};
  return R_BAD_JSON if !$pattern;
  foreach ( @$pattern ) {
    my $val = $json->{ $_->{name} };
    # если это необязательное поле и оно пустое, то пропускаем его
    if ( !$_->{mandatory} && !$val ) {
      next;
    }

    # если это обязательное поле и оно пустое, то ошибка
    return $self->errorCode($_) if ( !$val );

    # если тип параметра -- строка
    if ( $_->{type} eq "unicode" ) {
      # если длина строки не удовлетворяет требованиям, то ошибка
      if ( $_->{min} && length $val < $_->{min} ||
          length $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
    elsif ( $_->{type} eq "int" ) {
      # если число, передаваемое в параметре не удовлетворяет требованиям, то ошибка
      if ( $_->{min} && $val < $_->{min} ||
          $_->{max} && $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
  }
  #заменить нормальный кодом 
  if ($cmd eq 'register') {
    my $res = $self->checkUsername;
    return $res if $res;
    $res = $self->checkPassword;
    return $res if $res;
  }

  return R_ALL_OK;
}

sub errorCode() {
  my ($self, $paramInfo) = @_;
  return $paramInfo->{errorCode} || R_BAD_JSON;
}



# Команды, которые приходят от клиента
sub cmd_register {
  my ($self, $result) = @_;
  $self->{db}->addPlayer($self->{json}->{username}, $self->{json}->{password});
}

sub cmd_login {
  my ($self, $result) = @_;
  $self->{json}->{username};
  $self->{json}->{password};
}

sub cmd_logout {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_sendMessage {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{text};
}

sub cmd_getMessages {
  my ($self, $result) = @_;
  $self->{json}->{since};
}

sub cmd_createDefaultMaps {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_uploadMap {
  my ($self, $result) = @_;
  $self->{json}->{mapName};
  $self->{json}->{palyersNum};
  $self->{json}->{regions};
  $self->{json}->{turnsNum};
}

sub cmd_createGame {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{gameName};
  $self->{json}->{mapId};
  $self->{json}->{gameDescr};
}

sub cmd_getGameList {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_joinGame {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{gameId};
}

sub cmd_leaveGame {
  my ($self, $result) = @_;
  $self->{json}->{sid};
}

sub cmd_setReadinessStatus {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{isReady};
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

sub cmd_resetServer {
  my ($self, $result) = @_;
}

sub cmd_throwDice {
  my ($self, $result) = @_;
  $self->{json}->{sid};
  $self->{json}->{dice};
}

1;

__END__
