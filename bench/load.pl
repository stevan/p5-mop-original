#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark ':hireswallclock', 'cmpthese';

my $inc = join ' ', map { "-I '$_'" } @INC;

cmpthese(50, {
    mop   => sub { system("$^X $inc -e 'package Foo; use mop'") },
    Moose => sub { system("$^X $inc -e 'package Foo; use Moose'") },
    Mouse => sub { system("$^X $inc -e 'package Foo; use Mouse'") },
});
