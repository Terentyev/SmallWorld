package SW::DB;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use DBD::InterBase;
use DBI;

sub new {
  my $class = shift;
  my $self = { dbh => undef };

  bless $self, $class;
  $self->_init(@_);

  return $self;
}

sub _init {
  my $self = shift;
  my %p = (@_);
  $self->{dbh} = DBI->connect("DBI:InterBase:hostname=localhost;db=$p{db};ib_charset=UTF-8", $p{user}, $p{passwd}) ||
    $self->dbError;
  $self->{dbh}->{LongReadLen} = $p{maxBlobSize} if $p{maxBlobSize};
}

sub disconnect {
  $_[0]->{dbh}->disconnect if $_[0]->{dbh};
}

sub dbError {
  my ($self, $stmnt, @binds) = (@_, '');
  my $error = (defined $self->{dbh} ? ($self->{dbh}->errstr // '') : '') . "\n$stmnt\n" . Dumper(\@binds);
  die "DB error: $error\n";
}

sub commit {
  my $self = shift;
  $self->{dbh}->commit;
}

sub do {
  my ($self, $stmnt, @binds) = @_;
  $self->{dbh}->do($stmnt, undef, @binds) || $self->dbError($stmnt, @binds);
}

sub fetch1 {
  my ($self, $stmnt, @binds) = @_;
  return $self->{dbh}->selectrow_array($stmnt, undef, @binds);# || $self->dbError($stmnt);
}

sub fetchall {
  my ($self, $stmnt, @binds) = @_;
  return $self->{dbh}->selectall_arrayref($stmnt, { Slice => {} }, @binds) || $self->dbError($stmnt, @binds);
}

sub fetchcol {
  my ($self, $stmnt, @binds) = @_;
  return $self->{dbh}->selectcol_arrayref($stmnt, { Columns => [1] }, @binds) || $self->dbError($stmnt, @binds);
}

sub fetchrow {
  my ($self, $stmnt, @binds) = @_;
  return $self->{dbh}->selectrow_hashref($stmnt, undef, @binds) || $self->dbError($stmnt, @binds);
}

sub getId {
  my ($self, $name) = @_;
  return $self->fetch1("SELECT gen_id(GEN_$name\_ID, 0) FROM RDB\$DATABASE");
}

1;

__END__
