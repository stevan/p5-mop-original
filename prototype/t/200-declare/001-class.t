#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop ();
use mop::declare;

BEGIN {
    class Foo {}
}

my $Foo = Foo;
is( $Foo->get_name, 'Foo', '... got the name we expected' );

done_testing;