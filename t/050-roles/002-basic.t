#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

role Foo {}

can_ok( Foo, 'attribute_class' );
can_ok( Foo, 'method_class' );

can_ok( Foo, 'name' );
can_ok( Foo, 'version' );
can_ok( Foo, 'authority' );

can_ok( Foo, 'find_method' );
can_ok( Foo, 'methods' );

can_ok( Foo, 'find_attribute' );
can_ok( Foo, 'attributes' );

is( Foo->attribute_class, $::Attribute, '... got the expected value of attribute_class');
is( Foo->method_class, $::Method, '... got the expected value of method_class');

is( Foo->name, 'Foo', '... got the expected value for name');

role Bar {
    has $bar = 'bar';
    method bar { $bar }
}

my $method = Bar->find_method( 'bar' );
ok( $method->isa( $::Method ), '... got the method we expected' );
is( $method->name, 'bar', '... got the name of the method we expected');

my $attribute = Bar->find_attribute( '$bar' );
ok( $attribute->isa( $::Attribute ), '... got the attribute we expected' );
is( $attribute->name, '$bar', '... got the name of the attribute we expected');

done_testing;

