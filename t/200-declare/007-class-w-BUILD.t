#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {
    has $bar;

    BUILD ( $params ) {
        $bar .= $params->{'BAR'};
    }

    method bar { $bar }
}

is(Foo->name, 'Foo', '... got the name we expected');
is(Foo->superclass, $::Object, '... got the superclass we expected');

my $foo_constructor = Foo->constructor();
ok( $foo_constructor, '... found the BUILD method' );
ok( $foo_constructor->isa( $::Method ), '... it is a proper method');
is($foo_constructor->name, 'BUILD', '... got the right name for BUILD');

my $foo = Foo->new( bar => "HELLO", BAR => ' World' );
ok($foo->isa( Foo ), '... this is a Foo');
is(mop::class_of( $foo ), Foo, '... this is a Foo');

is($foo->bar, "HELLO World", '... returns what it is given');

done_testing;