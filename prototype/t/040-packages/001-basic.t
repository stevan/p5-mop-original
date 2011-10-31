#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {

    package Foo;

    use strict;
    use warnings;
    use mop;

    class Bar {
        has $baz;
    }
}

my $foo = Foo::Bar->new;
ok( $foo->isa( Foo::Bar ), '... the object is from class Foo' );
ok( $foo->isa( $::Object ), '... the object is derived from class Object' );
is( mop::class_of( $foo ), Foo::Bar, '... the class of this object is Foo' );
is( mop::class_of( $foo )->get_name, 'Foo::Bar', '... got the correct (fully qualified) name of the class');
like( "$foo", qr/^Foo::Bar/, '... object stringification includes fully qualified class name' );


BEGIN {
    package Bar;

    use strict;
    use warnings;
    use mop;

    our $FOO = 100_000;
    sub do_something { $_[0] + $_[1] }

    class Baz {
        has $gorch = 10;
        method foo {
            do_something( $gorch, $FOO )
        }
        method my_package { __PACKAGE__ }
    }
}

my $baz = Bar::Baz->new;
ok( $baz->isa( Bar::Baz ), '... the object is from class Baz' );
ok( $baz->isa( $::Object ), '... the object is derived from class Object' );
is( mop::class_of( $baz ), Bar::Baz, '... the class of this object is Baz' );

is( $baz->foo, 100_010, '... got the value we expected' );
is( $baz->my_package, 'Bar', '... got the value we expected' );

done_testing;
