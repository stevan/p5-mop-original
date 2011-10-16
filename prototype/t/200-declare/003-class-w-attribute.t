#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop ();
use mop::declare;

BEGIN {
    class Foo {
        has $bar = 100;
    }
}

is(Foo->get_name, 'Foo', '... got the name we expected');
is_deeply(Foo->get_superclasses, [ $::Object ], '... got the superclasses we expected');

my $bar = Foo->get_attributes->{'$bar'};
ok($bar, '... got a bar');
ok($bar->is_a( $::Attribute ), '... bar is a Attribute');
is($bar->get_name, '$bar', '... got the right name for bar');
is(${$bar->get_initial_value}, 100, '... got the right initial value for bar');

{
    my $foo = Foo->new;
    ok($foo->is_a( Foo ), '... this is a Foo');
    is($foo->class, Foo, '... this is a Foo');
    is(mop::internal::instance::get_slot_at( $foo, '$bar' ), 100, '... got the expected initial value');
}

{
    my $foo = Foo->new( bar => 200 );
    ok($foo->is_a( Foo ), '... this is a Foo');
    is($foo->class, Foo, '... this is a Foo');
    is(mop::internal::instance::get_slot_at( $foo, '$bar' ), 200, '... got the expected initial value');
}

done_testing;