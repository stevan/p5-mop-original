#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop ();
use mop::declare;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    method foo ( $bar, $baz ) {
        join ", " => $bar, $baz;
    }
}

my $method = $Foo->find_method('foo');
ok( $method, '... found the method' );

my $foo = $Foo->new;
is( $foo->foo( 10, 20 ), '10, 20', '... got the right value' );

done_testing;