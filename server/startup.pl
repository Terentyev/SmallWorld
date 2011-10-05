#!/usr/bin/perl

use Cwd 'abs_path';

$ENV{WIN32} = ($^O =~ m/MSWin32/i);
$ENV{DEBUG} = 1;

use lib abs_path($0);

1;
