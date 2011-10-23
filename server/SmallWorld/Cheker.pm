package SmallWorld::Cheker;


use strict;
use warnings;
use utf8;

use SmallWorld::Consts;
use SmallWorld::Config;
use SmallWorld::DB;

require Exporter;
our @ISA    = qw( Exporter );
our @EXPORT = qw( checkJsonCmd checkLoginAndPassword checkInGame checkPlayersNum checkIsStarted
                  checkRegions errorCode );

sub errorCode() {
  my ($self, $paramInfo) = @_;
  return $paramInfo->{errorCode} || R_BAD_JSON;
}

sub checkLoginAndPassword {
  my $self = shift;
  return !defined $self->{db}->query('SELECT 1 FROM PLAYERS WHERE username = ? and pass = ?',
                                     @{$self->{json}}{qw/username password/} );
}

sub checkInGame {
  my $self = shift;
  my $gameId = $self->{db}->query('SELECT c.gameId FROM PLAYERS p INNER JOIN CONNECTIONS c 
                                   ON p.id = c.playerId WHERE p.sid = ?', $self->{json}->{sid});
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
  $self->{db}->getGameIsStarted($gameId);
}

sub checkRegions {
  my $self = shift;
  my $s = 0;
  my $r = $self->{json}->{regions};
  my $l = @$r;
  my $ex;
  for (my $i = 0; $i < $l; ++$i){
    if (exists @$r[$i]->{population}) {
      return 1 if @$r[$i]->{population} !~ /^[+-]?\d+\z/ || @$r[$i]->{population} < 0;
      $s += @$r[$i]->{population};
    }
    return 1 if defined @$r[$i]->{landDescription} && ref @$r[$i]->{landDescription} ne 'ARRAY';
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
    return 1 if !defined @$r[$i]->{adjacent} || ref @$r[$i]->{adjacent} ne 'ARRAY';
    foreach my $j (@{@$r[$i]->{adjacent}}) {

      return 1 if !defined @$r[$j-1]->{adjacent} || ref @$r[$j-1]->{adjacent} ne 'ARRAY';
      #������ �������� � ������������ �������� ��� ����� �����
      return 1 if $j< 1 || $j > $l || $j == $i + 1;

      #������ A �������� � �������� B, � ������ B �� �������� � A
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
    # ���� ��� �������������� ���� � ��� ������, �� ���������� ���
    if ( !$_->{mandatory} && !defined $val ) {
      next;
    }

    # ���� ��� ������������ ���� � ��� ������, �� ������
    return $self->errorCode($_) if ( !defined $val );

    # ���� ��� ��������� -- ������
    if ( $_->{type} eq 'unicode' ) {
      # ���� ����� ������ �� ������������� �����������, �� ������
      return $self->errorCode($_) if ref(\$val) ne 'SCALAR';
      if ( defined $_->{min} && length $val < $_->{min} ||
          defined $_->{max} && length $val > $_->{max} ) {
        return $self->errorCode($_);
      }
    }
    elsif ( $_->{type} eq 'int' ) {
      # ���� �����, ������������ � ��������� �� ������������� �����������, �� ������
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
    &R_GAME_NAME_TAKEN  => sub { $self->{db}->dbExists('games', 'name', $self->{json}->{gameName}); },
    &R_BAD_GAME_STATE   => sub { $self->checkIsStarted($self->{json}); },
    &R_BAD_LOGIN        => sub { $self->checkLoginAndPassword(); },
    &R_BAD_MAP_ID       => sub { !$self->{db}->dbExists("maps", "id", $self->{json}->{mapId}); },
    &R_MAP_NAME_TAKEN   => sub { $self->{db}->dbExists('maps', 'name', $self->{json}->{mapName}); },
    &R_BAD_PASSWORD     => sub { $self->{json}->{password} !~ m/^.{6,18}$/; },
    &R_BAD_REGIONS      => sub { $self->checkRegions(); },
    &R_BAD_SID          => sub { defined $self->{json}->{sid} && !$self->{db}->dbExists("players", "sid", $self->{json}->{sid}); },
    &R_BAD_USERNAME     => sub { $self->{json}->{username} !~ m/^[A-Za-z][\w\-]*$/; },
    &R_NOT_IN_GAME      => sub { !defined $self->{db}->getGameId($self->{json}->{sid}); },
    &R_TOO_MANY_PLAYERS => sub { $self->checkPlayersNum(); },
    &R_USERNAME_TAKEN   => sub { $self->{db}->dbExists("players", "username", $self->{json}->{username}); },
    &R_BAD_REGION_ID    => sub { $self->{json}->{regionId} > SmallWorld::Game->new($self->{db}, $self->{json}->{sid})->regionsNum(); }
  };

  my $errorList = CMD_ERRORS->{$cmd};
  foreach ( @$errorList ) {
    return $_ if $errorHandlers->{$_}->();
  }

  return R_ALL_OK;
}

1;

__END__