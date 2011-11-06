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
    my $attribute = $Foo->attributes->{'$foo'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->isa( $::Attribute ), '... it is a proper attribute');
    is( $attribute->name, '$foo', '... got the right name');
    is( ${ $attribute->initial_value }->(), 10, '... got the right initial value' );
}

{
    my $attribute = $Foo->attributes->{'$bar'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->isa( $::Attribute ), '... it is a proper attribute');
    is( $attribute->name, '$bar', '... got the right name');
    is( ${ $attribute->initial_value }, undef, '... got the right initial value' );
}

done_testing;