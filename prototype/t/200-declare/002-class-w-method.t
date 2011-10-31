#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {
    method bar ( $baz ) { $baz }
}

is(Foo->get_name, 'Foo', '... got the name we expected');
is(Foo->get_superclass, $::Object, '... got the superclass we expected');

my $bar = Foo->find_method('bar');
ok($bar, '... got a bar');
ok($bar->is_a( $::Method ), '... bar is a Method');
is($bar->get_name, 'bar', '... got the right name for bar');

my $foo = Foo->new;
ok($foo->is_a( Foo ), '... this is a Foo');
is($foo->class, Foo, '... this is a Foo');

is($foo->bar(10), 10, '... returns what it is given');

done_testing;