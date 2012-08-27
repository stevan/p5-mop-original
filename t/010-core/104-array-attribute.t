#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $BAZ = [];

class Foo {
    has @bar = ('baz', $BAZ);
    method bar { \@bar }
};

my $foo = Foo->new;
is_deeply( $foo->bar, [ 'baz', [] ], '... got the expected value' );
is( $foo->bar->[1], $BAZ, '... these are the same values' );

{
    my $foo2 = Foo->new;
    is_deeply( $foo2->bar, [ 'baz', [] ], '... got the expected value' );

    isnt( $foo->bar, $foo2->bar, '... these are not the same values' );
    is( $foo2->bar->[1], $BAZ, '... these are the same values' );
    is( $foo->bar->[1], $foo2->bar->[1], '... these are the same values' );
}

done_testing;

