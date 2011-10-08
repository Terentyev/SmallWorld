package SmallWorld::DB;

use strict;
use warnings;
use utf8;

use SmallWorld::Conf;
use DBD::InterBase;
use DBI;

sub new {
  my $class = shift;
  my $self = {};
  $self->{dbh} = undef;
  bless $self, $class;
  return $self
}

sub dbError {
  my $self = shift;
  my $error =  defined $_[0] ? $_[0] : $self->{dbh}->errstr;
  die "DB error: $error";
}

sub connect {
  my $self = shift;
  my ($dbName, $dbLogin, $dbPassword, $dbMaxBlobSize) = @_;
  $self->{dbh} = DBI->connect("DBI:InterBase:hostname=localhost;db=$dbName", $dbLogin, $dbPassword)
    or $self->dbError; 
  $self->{dbh}->{LongReadLen} = $dbMaxBlobSize if $dbMaxBlobSize;
  $self->{dbh}->{AutoCommit} = 1;
}

sub disconnect {  
  $_[0]->{dbh}->disconnect;
}

sub _do {
  my $self = shift;
  my ($s, @list) = @_;
  $self->{dbh}->do($s, undef, @list) or $self->dbError;
}

sub dbExists {
  my $self = shift;
  my ($table, $field, $param) = @_;
  return defined $self->{dbh}->selectrow_array("SELECT id FROM $table WHERE $field = ?", undef, $param);
}

sub addPlayer {
  my $self = shift;  
  $self->_do("insert into players(username, pass) values(?,?)", @_);
}

1;

