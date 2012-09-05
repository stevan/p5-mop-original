#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {}
class Bar (extends => Foo) {}

is( Foo->name, 'Foo', '... got the name we expected' );
is(Foo->superclass, $::Object, '... got the superclass we expected');

is( Bar->name, 'Bar', '... got the name we expected' );
is( Bar->superclass, Foo, '... got the superclass we expected' );

done_testing;