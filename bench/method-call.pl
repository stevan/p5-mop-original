#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark ':hireswallclock', 'cmpthese';

use mop;

class Foo {
    method foo { 'FOO' }
    method bar ($x, $y) { $x + $y }
}

{
    package Bar;
    sub new { bless {}, shift }
    sub foo { 'FOO' }
    sub bar { my $self = shift; my ($x, $y) = @_; $x + $y }
}

my $foo = Foo->new;
my $bar = Bar->new;

cmpthese(1000000, {
    mop          => sub { $foo->foo },
    mop_args     => sub { $foo->bar(1, 2) },
    package      => sub { $bar->foo },
    package_args => sub { $bar->bar(1, 2) },
});
