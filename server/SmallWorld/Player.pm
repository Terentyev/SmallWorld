package SmallWorld::Player;


use strict;
use warnings;
use utf8;

use base ('SmallWorld::SafeObj');

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{game} = {@_}->{game};

  bless $self, $class;

  return $self;
}

# определяет принадлежит ли регион активной расе
sub activeConq {
  my ($self, $region) = @_;
  return
    ($self->{currentTokenBadge}->{tokenBadgeId} // -1)  == ($region->{tokenBadgeId} // -2);
}

sub isFriend {
  my ($self, $friendInfo) = @_;
  return
    defined $friendInfo && ($friendInfo->{friendId} // -1) == $self->{playerId};
}

sub id             { return $_[0]->{playerId};                                             }
sub name           { return $_[0]->{username};                                             }
sub coins          { return $_[0]->{coins};                                                }
sub activeRace     { return $_[0]->{game}->createRace($_[0]->{currentTokenBadge});         }
sub activeSp       { return $_[0]->{game}->createSpecialPower('currentTokenBadge', $_[0]); }
sub tokens         { return $_[0]->{tokensInHand};                                         }
sub activeRaceName { return $_[0]->{currentTokenBadge}->{raceName} // 'none';              }
sub activeSpName   { return $_[0]->{currentTokenBadge}->{specialPowerName} // 'none';      }
sub dice {
  my $self = shift;
  $self->{dice} = $_[0] if scalar(@_) == 1;
  return $self->{dice};
}

1;

__END__
