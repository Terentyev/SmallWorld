#!/usr/bin/perl

use File::Basename;

$ENV{WIN32} = ($^O =~ m/MSWin32/i);
$ENV{DEBUG} = 1;

BEGIN
{
  $path = dirname(__FILE__);
}
use lib $path;

1;
