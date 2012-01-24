package AI::DB;


use strict;
use warnings;
use utf8;

use SW::SqlBuilder;

use base('SW::DB');


sub _init {
  my $self = shift;
  $self->SUPER::_init(@_);
  $self->{dbh}->{AutoCommit} = 1;
  $self->{bldr} = SW::SqlBuilder->new();
}

sub select1 {
  my $self = shift;
  return $self->fetch1($self->{bldr}->select(@_));
}

sub selectall {
  my $self = shift;
  return $self->fetchall($self->{bldr}->select(@_));
}

sub selectcol {
  my $self = shift;
  return $self->fetchcol($self->{bldr}->select(@_));
}

sub selectrow {
  my $self = shift;
  return $self->fetchrow($self->{bldr}->select(@_));
}

sub insert {
  my $self = shift;
  $self->do($self->{bldr}->insert(@_));
}

sub delete {
  my $self = shift;
  $self->do($self->{bldr}->delete(@_));
}

sub update {
  my $self = shift;
  $self->do($self->{bldr}->update(@_));
}

1;

__END__
