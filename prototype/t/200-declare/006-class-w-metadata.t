#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {
    class Foo {}
    class Bar (extends => Foo()) {}
}

is( Foo->get_name, 'Foo', '... got the name we expected' );
is_deeply( Foo->get_superclasses, [ $::Object ], '... got the superclasses we expected' );

is( Bar->get_name, 'Bar', '... got the name we expected' );
is_deeply( Bar->get_superclasses, [ Foo ], '... got the superclasses we expected' );

done_testing;