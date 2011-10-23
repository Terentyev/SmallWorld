package Tests::BaseTest;


use strict;
use warnings;
use utf8;
use open qw( :std :utf8 ); # нужно, чтобы не выдавалось предупреждение "Wide character in print"

use JSON qw( decode_json encode_json );
use LWP::UserAgent;
use URI::Escape;

use Tests::Config;

sub new {
  my $class = shift;
  my $self = { desc => "", ua => LWP::UserAgent->new };

  bless $self, $class;

  return $self;
}

sub getInFiles {
  return <$_[1]/*._in>;
}

sub run {
  my ($self, $dir) = @_;
  print "$self->{desc}:\n  Директория: $dir\n";

  foreach ( $self->getInFiles($dir) ) {
    $self->check($_);
  }
}

sub check {
  my ($self, $in) = @_;
  my $ans = $in;
  $ans =~ s/\.[^\.]+$/.ans/;

  my $answers = decode_json($self->readFile($ans));
  my $inTest = decode_json($self->readFile($in));
  my $i = 0;
  if ( !defined $inTest->{description} ) {
    $inTest->{description} = $in;
  }
  print "   $inTest->{description}: ";
  foreach ( @{ $inTest->{test} } ) {
    my $req = encode_json($_);
    my $cnt = $self->sendRequest($req);

    if ( $self->compare($answers->[$i], eval { return decode_json($cnt) || {}; }) ) {
      print ".";
    }
    else {
      print "X";
      $self->addReport($in, $i, $req, encode_json($answers->[$i]), $cnt);
    }
    #printf("%d: %s != %s\n", $i + 1, $cnt, encode_json($answers->[$i]));
    $i++;
  }
  print "\n";
}

sub readFile {
  my ($self, $file) = @_;
  local $/ = undef;
  open(FILE, $file);
  my $result = <FILE>;
  close(FILE);
  return $result;
}

sub sendRequest {
  my ($self, $query) = @_;
  my $req = HTTP::Request->new(POST => "http://" . SERVER_ADDRESS . "/");
  $req->content_type("application/x-www-form-urlencoded");
  $req->content("request=" . uri_escape($query));
  return $self->{ua}->request($req)->content;
}

sub addReport {
  my ($self, $file, $num, $query, $ethalon, $content) = @_;
  push(@{ $self->{report}->{$file} }, { num => $num + 1, query => $query, ethalon => $ethalon, content => $content });
}

sub outReport {
  my ($self) = @_;
#use Data::Dumper; print Dumper($self);
  foreach my $file (sort keys %{ $self->{report} }) {
    print "  $file:\n";
    foreach ( @{ $self->{report}->{$file} } ) {
      print "    $_->{num}: Request:  $_->{query}\n";
      print "       Expected: $_->{ethalon}\n";
      print "       Get:      $_->{content}\n";
    }
  }
}

sub compare {
  my ($self, $eth, $cnt) = @_;

  return 1 if ! defined $eth && ! defined $cnt;
  return 0 if ! defined $eth || ! defined $cnt;
  return 0 if ref $eth ne ref $cnt;

  my $res = 1;
  if ( ref $eth eq "HASH" ) {
    return 0 if scalar(keys %$eth) != scalar(keys %$cnt);
    foreach (keys %{ $eth }) {
      $res = $self->compare($eth->{$_}, $cnt->{$_});
      return 0 if !$res;
    }
  }
  elsif ( ref $eth eq "ARRAY" ) {
    return 0 if scalar(@$eth) != scalar(@$cnt);
    for (my $i = 0; $i < @$eth; ++$i) {
      $res = $self->compare($eth->[$i], $cnt->[$i]);
      return 0 if !$res;
    }
  }
  else {
    $res = $eth eq $cnt;
  }
  return $res;
}

1;

__END__
