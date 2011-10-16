#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop ();
use mop::declare;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    has $foo = 10;
}

my $attribute = $Foo->get_attributes->{'$foo'};
ok( $attribute, '... found the attribute' );
is( $attribute->get_name, '$foo', '... got the right name');
is( ${ $attribute->get_initial_value }, 10, '... got the right initial value' );

done_testing;