package Tests::BaseTest;


use strict;
use warnings;
use utf8;
use open qw( :std :utf8 ); # нужно, чтобы не выдавалось предупреждение "Wide character in print"

use File::Basename qw( dirname );
use File::Spec;
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

sub include {
  my ($self, $file, $dir) = @_;
  my $include = decode_json($self->readFile(File::Spec->catfile($dir, $file)));
  foreach ( @{ $include } ) {
    my $result = $self->sendRequest(encode_json($_));
    die "Failed include '$file'
Request: " . encode_json($_) . "
Result: $result" if eval { return decode_json($result)->{result} or ''; } ne 'ok';
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
  if ( @{ $inTest->{test} } != @{ $answers } ) {
    print "count of answers not equal count of tests\n";
    return;
  }
  foreach ( @{ $inTest->{include} } ) {
    $self->include($_, dirname($in));
  }
  foreach ( @{ $inTest->{test} } ) {
    my $req = encode_json($_);
    my $cnt = $self->sendRequest($req);
    my $diff = '';

    if ( $self->compare($answers->[$i], eval { return decode_json($cnt) || {}; }, $diff) ) {
      print '.';
    }
    else {
      print 'X';
      $self->addReport($in, $i, $req, encode_json($answers->[$i]), $cnt, $diff);
    }
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
#  $req->content_type("multipart/form-data");
  $req->add_content_utf8($query);
  return $self->{ua}->request($req)->content;
}

sub addReport {
  my ($self, $file, $num, $query, $ethalon, $content, $diff) = @_;
  push(@{ $self->{report}->{$file} }, { num => $num + 1, query => $query, ethalon => $ethalon, content => $content, diff => $diff});
}

sub outReport {
  my ($self) = @_;
  foreach my $file (sort keys %{ $self->{report} }) {
    print "  $file:\n";
    foreach ( @{ $self->{report}->{$file} } ) {
      print "    $_->{num}: Request:  $_->{query}\n";
      print "       Expected: $_->{ethalon}\n";
      print "       Get:      $_->{content}\n";
      print "       Diff:     $_->{diff}\n";
    }
  }
}

sub compare {
  my ($self, $eth, $cnt, $diff) = @_;

  return 1 if ! defined $eth && ! defined $cnt;
  return 0 if ! defined $eth || ! defined $cnt;
  return 0 if ref $eth ne ref $cnt;

  if ( ref $eth eq "HASH" ) {
# не поддерживаю идею точного совпадения результата сервера и эталонного ответа.
# Сервер должен только содержать ответ, но может быть более полным.
#return 0 if scalar(keys %$eth) != scalar(keys %$cnt);
#    if ( !$self->compare([sort keys %$eth], [sort keys %$cnt], $_[3]) ) {
#      $_[3] .= ':different keys';
#      return 0;
#    }
    foreach (keys %{ $eth }) {
      my $tmpDiff = "$diff/$_";
      if ( !$self->compare($eth->{$_}, $cnt->{$_}, $tmpDiff) ) {
        $_[3] = $tmpDiff;
        return 0;
      }
    }
  }
  elsif ( ref $eth eq "ARRAY" ) {
    if ( scalar(@$eth) != scalar(@$cnt) ) {
      $_[3] .= ':different array length';
      return 0;
    }
    for (my $i = 0; $i < @$eth; ++$i) {
      my $tmpDiff = "$diff [$i]";
      if ( !$self->compare($eth->[$i], $cnt->[$i], $tmpDiff) ) {
        $_[3] = $tmpDiff;
        return 0;
      }
    }
  }
  elsif ( $eth ne $cnt ) {
    $_[3] .= ":{'$eth' vs '$cnt'}";
    return 0;
  }
  return 1;
}

1;

__END__
