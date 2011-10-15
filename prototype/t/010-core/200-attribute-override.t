#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {

    my ($self, $class);

    class 'Foo' => sub {
        has( my $bar ) = 10;
        method 'bar' => sub { $bar };
    };

    class 'FooBar' => ( extends => Foo() ) => sub {
        has( my $bar );
        method 'derived_bar' => sub { $bar };
    };
}

my $foobar = FooBar->new( bar => 100 );

is($foobar->bar, 100, '... got the expected value (for the superclass method)');
is($foobar->derived_bar, 100, '... got the expected value (for the derived method)');

done_testing;
