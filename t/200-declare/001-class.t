#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {}

is( Foo->name, 'Foo', '... got the name we expected' );
is( Foo->superclass, $::Object, '... got the superclass we expected' );

done_testing;