#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop::mini;

my $BAZ = [];

class Foo {
    has %bar = (baz => $BAZ);
    has %baz;
    method bar { \%bar }
    method baz { \%baz }
};

my $foo = Foo->new;
is_deeply( $foo->bar, { baz => [] }, '... got the expected value' );
is( $foo->bar->{'baz'}, $BAZ, '... these are the same values' );

{
    my $foo2 = Foo->new;
    is_deeply( $foo2->bar, { baz => [] }, '... got the expected value' );

    isnt( $foo->bar, $foo2->bar, '... these are not the same values' );
    is( $foo2->bar->{'baz'}, $BAZ, '... these are the same values' );
    is( $foo->bar->{'baz'}, $foo2->bar->{'baz'}, '... these are the same values' );
}

my $foo3 = Foo->new(baz => { quux => 1 });
is_deeply( $foo3->baz, { quux => 1 });

done_testing;

