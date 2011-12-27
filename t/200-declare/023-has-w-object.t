#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $Foo = $::Class->new;

my $has_Bar_been_created = 0;

class Bar {
    BUILD { $has_Bar_been_created = 1 }
}

{
    local $::CLASS = $Foo;

    has $foo = Bar->new;
}

{
    my $attribute = $Foo->get_all_attributes->{'$foo'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->isa( $::Attribute ), '... it is a proper attribute');
    is( $attribute->get_name, '$foo', '... got the right name');

    ok(!$has_Bar_been_created, '... no Bar instances have been created yet');

    my $bar1 = ${ $attribute->get_initial_value }->();
    ok( $bar1->isa( Bar ), '... got the right initial value' );

    ok($has_Bar_been_created, '... a Bar instance has been created now');

    my $bar2 = ${ $attribute->get_initial_value }->();
    ok( $bar2->isa( Bar ), '... got the right initial value (again)' );

    isnt( $bar1, $bar2, '... these are two distinct instances' );
}

done_testing;