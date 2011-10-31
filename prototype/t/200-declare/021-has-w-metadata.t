#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    has $bar ( initial_value => \200 );
}

{
    my $attribute = $Foo->get_attributes->{'$bar'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->isa( $::Attribute ), '... it is a proper attribute');
    is( $attribute->get_name, '$bar', '... got the right name');
    is( ${ $attribute->get_initial_value }, 200, '... got the right initial value' );
}

done_testing;