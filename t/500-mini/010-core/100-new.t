#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop::mini;

=pod

Every new instance created should be a new reference
but it should link back to the same class data.

=cut

class Foo {}

my $foo = Foo->new;
like( "$foo", qr/^Foo/, '... object stringification includes the class name' );

{
    my $foo2 = Foo->new;
    isnt( $foo, $foo2, '... these are not the same objects' );
}

done_testing;
