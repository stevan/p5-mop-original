#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    my $counter = 0;

    has $bar = { $counter++; [ map { $_ + $counter } 0 .. 5 ] };

    has $baz = +{ one => 1 };
}

{
    my $attribute = $Foo->get_attributes->{'$bar'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->is_a( $::Attribute ), '... it is a proper attribute');
    is( $attribute->get_name, '$bar', '... got the right name');
    is_deeply(
        ${ mop::internal::attribute::get_initial_value_for_instance( $attribute ) },
        [ 1, 2, 3, 4, 5, 6 ],
        '... got the right initial value'
    );
    is_deeply(
        ${ mop::internal::attribute::get_initial_value_for_instance( $attribute ) },
        [ 2, 3, 4, 5, 6, 7 ],
        '... got the right initial value'
    );
    is_deeply(
        ${ mop::internal::attribute::get_initial_value_for_instance( $attribute ) },
        [ 3, 4, 5, 6, 7, 8 ],
        '... got the right initial value'
    );
}

{
    my $attribute = $Foo->get_attributes->{'$baz'};
    ok( $attribute, '... found the attribute' );
    ok( $attribute->is_a( $::Attribute ), '... it is a proper attribute');
    is( $attribute->get_name, '$baz', '... got the right name');
    is_deeply(
        ${ mop::internal::attribute::get_initial_value_for_instance( $attribute ) },
        { one => 1 },
        '... got the right initial value'
    );
}

done_testing;