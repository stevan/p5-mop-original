#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

Every new instance created should be a new reference
but it should link back to the same class data.

=cut

BEGIN {

    class Foo {}
}

my $foo = Foo->new;
ok( $foo->is_a( Foo ), '... the object is from class Foo' );
ok( $foo->is_a( $::Object ), '... the object is derived from class Object' );
is( $foo->class, Foo, '... the class of this object is Foo' );
like( "$foo", qr/^Foo/, '... object stringification includes the class name' );

{
    my $foo2 = Foo->new;
    ok( $foo2->is_a( Foo ), '... the object is from class Foo' );
    ok( $foo2->is_a( $::Object ), '... the object is derived from class Object' );
    is( $foo2->class, Foo, '... the class of this object is Foo' );

    isnt( $foo, $foo2, '... these are not the same objects' );
    is( $foo->class, $foo2->class, '... these two objects share the same class' );
}

done_testing;
