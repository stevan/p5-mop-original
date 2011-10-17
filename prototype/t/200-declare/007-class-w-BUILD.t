#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {
    class Foo {
        has $bar;

        BUILD ( $params ) {
            $bar .= $params->{'BAR'};
        }

        method bar { $bar }
    }
}

is(Foo->get_name, 'Foo', '... got the name we expected');
is_deeply(Foo->get_superclasses, [ $::Object ], '... got the superclasses we expected');

my $foo_constructor = Foo->get_constructor();
ok( $foo_constructor, '... found the BUILD method' );
ok( $foo_constructor->is_a( $::Method ), '... it is a proper method');
is($foo_constructor->get_name, 'BUILD', '... got the right name for BUILD');

my $foo = Foo->new( bar => "HELLO", BAR => ' World' );
ok($foo->is_a( Foo ), '... this is a Foo');
is($foo->class, Foo, '... this is a Foo');

is($foo->bar, "HELLO World", '... returns what it is given');

done_testing;