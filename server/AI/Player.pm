package AI::Player;


use strict;
use warnings;
use utf8;

use SmallWorld::Consts;


sub new {
  my $class = shift;
  my $self = {
    games => {},
    @_
  };

  bless $self, $class;

  return $self;
}

sub _get {
  my ($self, $cmd) = @_;
  return $self->{req}->get($cmd);
}

sub do {
  my ($self, $game) = @_;
  if ( $game->{state} == GST_WAIT ) {
    $self->join2Game($game);
    return;
  }

  if ( $self->ourTurn( $game ) ) {
    $self->play($game);
    return;
  }
}

sub join2Game {
  my ($self, $game) = @_;
  my $r = $self->_get('{ "action": "aiJoin", "gameId": ' . $game->{gameId} . ' }');
  return if $r->{result} ne R_ALL_OK;

  my $g = $self->{games}->{$game->{gameId}};
  if ( !defined $g ) {
    $g = { gs => undef, ais => [] };
  }
  push @{ $g->{ais} }, { id => $r->{id}, sid => $r->{sid} };
  $self->{games}->{$game->{gameId}} = $g;
}

sub ourTurn {
  my ($self, $game) = @_;
  my $g = $self->{games}->{$game->{gameId}};
  return 0 if !defined $g;

  my $r = $self->_get('{ "action": "getGameState", "gameId": ' . $game->{gameId} . ' }');
  return if $r->{result} ne R_ALL_OK;

  $g->{gs} = $r->{gameState};
  return (grep { $_->{id} == $g->{gs}->{activePlayerId} } @{ $g->{ais} });
}

sub play {
  my ($self, $game) = @_;
  my $g = $self->{games}->{$game->{gameId}};
#  TODO
}

1;

__END__
