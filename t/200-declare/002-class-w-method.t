#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {
    method bar ( $baz ) { $baz }
}

SKIP: { skip "Requires the full mop", 5 if $ENV{PERL_MOP_MINI}; $::Object = $::Object; $::Method = $::Method;
is(Foo->name, 'Foo', '... got the name we expected');
is(Foo->superclass, $::Object, '... got the superclass we expected');

my $bar = Foo->find_method('bar');
ok($bar, '... got a bar');
ok($bar->isa( $::Method ), '... bar is a Method');
is($bar->name, 'bar', '... got the right name for bar');
}

my $foo = Foo->new;
ok($foo->isa( Foo ), '... this is a Foo');
is(mop::class_of( $foo ), Foo, '... this is a Foo');

is($foo->bar(10), 10, '... returns what it is given');

done_testing;
