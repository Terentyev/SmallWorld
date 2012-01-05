#!/usr/bin/perl

use File::Basename qw( dirname );

$ENV{WIN32}      = ($^O =~ m/MSWin32/i);
$ENV{DEBUG}      = 1;
$ENV{DEBUG_DICE} = 0;
$ENV{LENA}       = 0; # для тестов Лены Васильевой

BEGIN
{
  $path = dirname(__FILE__);
}
use lib $path;

1;
