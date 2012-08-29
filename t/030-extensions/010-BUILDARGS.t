#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

class FooMeta (extends => $::Class) {
    method BUILDARGS (@args) {
        unshift @args, 'bar' if @args % 2 == 1;
        return { @args };
    }
}

class Foo (metaclass => FooMeta) {
    has $bar;
    has $baz;

    method bar { $bar }
    method baz { $baz }
}

class Bar (extends => Foo) { }

for my $class (Foo, Bar) {
    is($class->new->bar, undef);
    is($class->new(bar => 42)->bar, 42);
    is($class->new(37)->bar, 37);
    {
        my $o = $class->new(bar => 42, baz => 47);
        is($o->bar, 42);
        is($o->baz, 47);
    }
    {
        my $o = $class->new(42, baz => 47);
        is($o->bar, 42);
        is($o->baz, 47);
    }
}

done_testing;
