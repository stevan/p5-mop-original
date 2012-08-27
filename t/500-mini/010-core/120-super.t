#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop::mini;


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
is( $foo->foo, 'FOO-FOOBAR-FOOBARBAZ-FOOBARBAZGORCH', '... got the chained super calls as expected');

done_testing;
