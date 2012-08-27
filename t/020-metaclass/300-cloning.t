#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

class Foo (with => [$::Cloneable]) {
    has $foo;
    has $bar;
    method foo { $foo }
    method bar { $bar }
}

ok(Foo->find_method('clone'), "has a clone method");

{
    my $foo = Foo->new(foo => "FOO", bar => "BAR");
    is($foo->foo, "FOO");
    is($foo->bar, "BAR");

    my $foo2 = $foo->clone;
    is($foo2->foo, "FOO");
    is($foo2->bar, "BAR");

    my $FOO = [];
    my $foo3 = $foo->clone(foo => $FOO);
    is($foo3->foo, $FOO);
    is($foo3->bar, "BAR");

    my $foo4 = $foo3->clone;
    is($foo4->foo, $FOO);
    is($foo4->bar, "BAR");
}

done_testing;
