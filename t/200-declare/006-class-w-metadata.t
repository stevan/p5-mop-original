#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {}
class Bar (extends => Foo) {}

SKIP: { skip "Requires the full mop", 4 if $ENV{PERL_MOP_MINI}; $::Object = $::Object;
is( Foo->name, 'Foo', '... got the name we expected' );
is(Foo->superclass, $::Object, '... got the superclass we expected');

is( Bar->name, 'Bar', '... got the name we expected' );
is( Bar->superclass, Foo, '... got the superclass we expected' );
}

isa_ok(Bar->new, Foo);

done_testing;
