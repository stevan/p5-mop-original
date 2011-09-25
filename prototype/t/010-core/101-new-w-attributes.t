#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

Every new instance created should be a new reference
and all attribute data in it should be a clone of the
original data itself.

=cut

my $BAZ;

BEGIN {

    my ($self, $class);

    $BAZ = [];

    class 'Foo' => sub {
        has( my $bar ) = { baz => $BAZ };
        method 'bar' => sub { $bar };
    };
}

my $foo = Foo->new;
is_deeply( $foo->bar, { baz => [] }, '... got the expected value' );
isnt( $foo->bar->{'baz'}, $BAZ, '... these are not the same values' );

{
    my $foo2 = Foo->new;
    is_deeply( $foo2->bar, { baz => [] }, '... got the expected value' );

    isnt( $foo->bar, $foo2->bar, '... these are not the same values' );
    isnt( $foo2->bar->{'baz'}, $BAZ, '... these are not the same values' );
    isnt( $foo->bar->{'baz'}, $foo2->bar->{'baz'}, '... these are not the same values' );
}

done_testing;
