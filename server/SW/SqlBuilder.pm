package SW::SqlBuilder;


use strict;
use warnings;
use utf8;


sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;

  return $self;
}

# За пример брался модуль SQL::Abstract
# (http://search.cpan.org/~frew/SQL-Abstract-1.72/lib/SQL/Abstract.pm)
# Но реализовано далеко не все

sub insert {
  my ($self, %p) = @_;
  return (
      "INSERT INTO $p{into}(" . join(',', keys %{ $p{values} }) . ') '
      . 'VALUES(' . join(',', (('?') x scalar(keys %{ $p{values} }))) . ')',
      values %{ $p{values} });
}

sub delete {
  my ($self, %p) = @_;
  my %where = $self->_getCondition('WHERE', $p{where});
  return ("DELETE FROM $p{from} $where{stmnt}", @{ $where{binds} });
}

sub update {
  my ($self, %p) = @_;
  my %set = $self->_getSetStmnt($p{set});
  my %where = $self->_getWhereStmnt($p{where});
  return (
      "UPDATE $p{update} $set{stmnt} $where{stmnt}",
      @{ $set{binds} }, @{ $where{binds} });
}

sub select {
  my $self = shift;
  my %p = (
      fields => '*',
      where  => '',
      order  => undef,
      @_);
  my %where = $self->_getWhereStmnt($p{where});
  return (
      "SELECT " . join(',', @{ $p{fields} })
      . " FROM $p{from} $where{stmnt} "
      . (defined $p{order} ? "ORDER BY $p{order}" : ''),
      @{ $where{binds} });
}

sub _constructCondition {
  my ($self, $name, $val, $op, $result) = @_;
  if ( ref($val) eq 'ARRAY' ) {
    my $t = '';
    foreach ( @$val ) {
      $t .= ' OR ' if $t ne '';
      $t .= $self->_construct($name, $_, $op, $result);
    }
    $t = "($t)" if $t ne '';
    return $t;
  }

  if ( ref($val) eq 'HASH' ) {
    my $t = '';
    foreach ( keys %$val ) {
      $t .= ' AND ' if $t ne '';
      $t .= $self->_construct($name, $val->{$_}, $_, $result);
    }
    return $t;
  }

  push @{ $result->{binds} }, $val if defined $val;
  return "$name $op " . (defined $val ? '?' : 'NULL');
}

sub _getSetOrWhereStmnt {
  my ($self, $p, $concOp, $prefix) = @_;
  my %result = ( stmnt => '', binds => [] );
  foreach ( keys %$p ) {
    $result{stmnt} .= $concOp if $result{stmnt};
    $result{stmnt} .= $self->_constructCondition($_, $p->{$_}, '=', \%result);
  }
  $result{stmnt} = $prefix . ' ' . $result{stmnt} if $result{stmnt} ne '';
  return %result;
}

sub _getSetStmnt {
  my ($self, $p) = @_;
  return $self->_getSetOrWhereStmnt($p, ', ', 'SET');
}

sub _getWhereStmnt {
  my ($self, $p) = @_;
  return $self->_getSetOrWhereStmnt($p, ' AND ', 'WHERE');
}

1;

__END__
