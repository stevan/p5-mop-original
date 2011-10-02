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

BEGIN {
    package Bar;

    use strict;
    use warnings;
    use mop;

    my ($self, $class);

    our $FOO = 100_000;
    sub do_something { $_[0] + $_[1] }

    class 'Baz' => sub {
        has( my $gorch ) = 10;
        method 'foo' => sub {
            do_something( $gorch, $FOO )
        };
    };
}

my $baz = Bar::Baz->new;
ok( $baz->is_a( Bar::Baz ), '... the object is from class Baz' );
ok( $baz->is_a( $::Object ), '... the object is derived from class Object' );
is( $baz->class, Bar::Baz, '... the class of this object is Baz' );

is( $baz->foo, 100_010, '... got the value we expected' );

done_testing;
