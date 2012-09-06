#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {}

SKIP: { skip "Requires the full mop", 2 if $ENV{PERL_MOP_MINI}; $::Object = $::Object;
is( Foo->name, 'Foo', '... got the name we expected' );
is( Foo->superclass, $::Object, '... got the superclass we expected' );
}

isa_ok(Foo->new, Foo);

done_testing;
