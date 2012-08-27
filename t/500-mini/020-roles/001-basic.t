#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop::mini;

role Foo {
    has $foo = 23;
    method foo ($x) { $x + $foo }
}

class Bar (roles => [Foo]) {
    has $bar = 7;
    method bar ($y) { $bar * $self->foo($y) }
}

is(Bar->new->bar(5), 196);

done_testing;
