#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    method foo ( $bar, $baz ) {
        join ", " => $bar, $baz;
    }

    method bar () { "BAR" }

    method baz { "BAZ" }
}

my $foo_method = $Foo->find_method('foo');
ok( $foo_method, '... found the foo method' );
ok( $foo_method->is_a( $::Method ), '... it is a proper method');

my $bar_method = $Foo->find_method('bar');
ok( $bar_method, '... found the bar method' );
ok( $bar_method->is_a( $::Method ), '... it is a proper method');

my $baz_method = $Foo->find_method('baz');
ok( $baz_method, '... found the baz method' );
ok( $baz_method->is_a( $::Method ), '... it is a proper method');

my $foo = $Foo->new;
is( $foo->foo( 10, 20 ), '10, 20', '... got the right value from ->foo' );
is( $foo->bar, 'BAR', '... got the right value from ->bar' );
is( $foo->baz, 'BAZ', '... got the right value from ->baz' );

done_testing;