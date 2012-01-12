package SmallWorld::Player;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');


sub _init {
  my $self = shift;
  $self->{game} = {@_}->{game};
}

sub _dropObj {
  my $self = shift;
  delete $self->{game};
}

sub isOwned {
  my ($self, $region) = @_;
  return $self->id == ($region->{ownerId} // -1);
}

# определяет принадлежит ли регион активной расе
sub activeConq {
  my ($self, $region) = @_;
  return
    ($self->{currentTokenBadge}->{tokenBadgeId} // -1)  == ($region->{tokenBadgeId} // -2);
}

sub isFriend {
  my ($self, $diplomat) = @_;
  my $friendInfo = $self->{game}->{gameState}->{friendInfo};
  return
    defined $friendInfo && ($friendInfo->{friendId} // -1) == $self->{playerId} && (
    !defined $diplomat || $diplomat->id == ($friendInfo->{diplomatId} // -1));
}

sub id                   { return $_[0]->{playerId};                                             }
sub name                 { return $_[0]->{username};                                             }
sub coins                { return $_[0]->{coins};                                                }
sub activeTokenBadgeId   { return $_[0]->{currentTokenBadge}->{tokenBadgeId};                    }
sub declinedTokenBadgeId { return $_[0]->{declinedTokenBadge}->{tokenBadgeId};                   }
sub activeRace           { return $_[0]->{game}->createRace($_[0]->{currentTokenBadge});         }
sub activeSp             { return $_[0]->{game}->createSpecialPower('currentTokenBadge', $_[0]); }
sub declinedRace         { return $_[0]->{game}->createRace($_[0]->{decliendTokenBadge});        }
sub activeRaceName       { return $_[0]->{currentTokenBadge}->{raceName} // 'none';              }
sub activeSpName         { return $_[0]->{currentTokenBadge}->{specialPowerName} // 'none';      }
sub tokens {
  my $self = shift;
  $self->{tokensInHand} = $_[0] if defined $_[0];
  return $self->{tokensInHand};
}
sub dice {
  my $self = shift;
  $self->{dice} = $_[0] if scalar(@_) == 1;
  return $self->{dice};
}
sub regions {
  my $self = shift;
  my @result = ();
  foreach ( $self->{game}->regions ) {
    push @result, $_ if ($_->{ownerId} // -1) == $self->id;
  }
  return wantarray ? @result : \@result;
}

1;

__END__
