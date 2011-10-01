#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {

    package Foo;

    use strict;
    use warnings;
    use mop;

    my ($self, $class);

    class 'Bar' => sub {
        has( my $baz );
    };

}

my $foo = Foo::Bar->new;
ok( $foo->is_a( Foo::Bar ), '... the object is from class Foo' );
ok( $foo->is_a( $::Object ), '... the object is derived from class Object' );
is( $foo->class, Foo::Bar, '... the class of this object is Foo' );

done_testing;
