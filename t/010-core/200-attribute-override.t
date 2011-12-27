#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This test illustrates the "virtual" nature of
attributes. While they are not public (meaning
they are not accessible from outside the class)
they are maybe better described as "protected",
however, even that is not quite right. The best
description really is "virtual", and really maps
to what an old school Perl OO programmer might
expect.

The key thing here is predictability, no one
likes to have to remember complex rules. This
may seem unsophisticated to some, but it is
understandable to everyone else.

=cut

use mop;

class Foo {
    has $bar = 10;
    method bar { $bar }
}

class FooBar ( extends => Foo ) {
    has $bar = 100;
    method derived_bar { $bar }
}

my $foobar = FooBar->new;

is($foobar->bar, 100, '... got the expected value (for the superclass method)');
is($foobar->derived_bar, 100, '... got the expected value (for the derived method)');

done_testing;
