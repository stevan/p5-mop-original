#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;


class Foo {
    method foo { "FOO" }
}

class FooBar ( extends => Foo ) {
    method foo { super . "-FOOBAR" }
}

class FooBarBaz ( extends => FooBar ) {
    method foo { super . "-FOOBARBAZ" }
}

class FooBarBazGorch ( extends => FooBarBaz ) {
    method foo { super . "-FOOBARBAZGORCH" }
}

my $foo = FooBarBazGorch->new;
ok( $foo->isa( FooBarBazGorch ), '... the object is from class FooBarBazGorch' );
ok( $foo->isa( FooBarBaz ), '... the object is from class FooBarBaz' );
ok( $foo->isa( FooBar ), '... the object is from class FooBar' );
ok( $foo->isa( Foo ), '... the object is from class Foo' );
SKIP: { skip "Requires the full mop", 1 if $ENV{PERL_MOP_MINI}; $::Object = $::Object;
ok( $foo->isa( $::Object ), '... the object is derived from class Object' );
}
is( mop::class_of( $foo ), FooBarBazGorch, '... the class of this object is FooBarBaz' );

is( $foo->foo, 'FOO-FOOBAR-FOOBARBAZ-FOOBARBAZGORCH', '... got the chained super calls as expected');

done_testing;
