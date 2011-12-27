#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {}
class Bar (extends => Foo) {}

is( Foo->get_name, 'Foo', '... got the name we expected' );
is(Foo->get_superclass, $::Object, '... got the superclass we expected');

is( Bar->get_name, 'Bar', '... got the name we expected' );
is( Bar->get_superclass, Foo, '... got the superclass we expected' );

done_testing;