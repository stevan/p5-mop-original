#!/usr/bin/env perl
use strict;
use warnings;
use 5.014;
use Test::More;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

my $i;
class Foo {
    has $foo (
        lazy      => 1,
        reader    => 'foo',
        builder   => '_build_foo',
        predicate => 'has_foo',
        clearer   => 'clear_foo',
    );

    method _build_foo { ++$i }
}

{
    $i = 0;
    my $foo = Foo->new;
    ok(!$foo->has_foo);
    is($foo->foo, 1);
    ok($foo->has_foo);
    $foo->clear_foo;
    ok(!$foo->has_foo);
    is($foo->foo, 2);
    ok($foo->has_foo);
}

{
    $i = 0;
    my $foo = Foo->new(foo => 5);
    ok($foo->has_foo);
    is($foo->foo, 5);
    $foo->clear_foo;
    ok(!$foo->has_foo);
    is($foo->foo, 1);
    ok($foo->has_foo);
}

class Bar {
    has $bar (
        lazy      => 1,
        reader    => 'bar',
        predicate => 'has_bar',
        clearer   => 'clear_bar',
    ) = do { ++$i };
}

{
    $i = 0;
    my $bar = Bar->new;
    { local $TODO = "lazy + default doesn't work yet";
    ok(!$bar->has_bar);
    }
    is($bar->bar, 1);
    ok($bar->has_bar);
    $bar->clear_bar;
    ok(!$bar->has_bar);
    { local $TODO = "lazy + default doesn't work yet";
    is($bar->bar, 2);
    ok($bar->has_bar);
    }
}

{
    $i = 0;
    my $bar = Bar->new(bar => 5);
    ok($bar->has_bar);
    is($bar->bar, 5);
    $bar->clear_bar;
    ok(!$bar->has_bar);
    { local $TODO = "lazy + default doesn't work yet";
    is($bar->bar, 1);
    ok($bar->has_bar);
    }
}

done_testing;
