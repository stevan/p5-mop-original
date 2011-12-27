#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    has $foo = 10;
    has $bar;
}

{
    my $attribute = $Foo->get_all_attributes->{'$foo'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->isa( $::Attribute ), '... it is a proper attribute');
    is( $attribute->get_name, '$foo', '... got the right name');
    is( ${ $attribute->get_initial_value }->(), 10, '... got the right initial value' );
}

{
    my $attribute = $Foo->get_all_attributes->{'$bar'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->isa( $::Attribute ), '... it is a proper attribute');
    is( $attribute->get_name, '$bar', '... got the right name');
    is( ${ $attribute->get_initial_value }, undef, '... got the right initial value' );
}

done_testing;