#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

role Foo {}

=cut

my $Foo = $::Role->new(
    name      => 'Foo',
    version   => '0.01',
    authority => 'cpan:STEVAN'
);

can_ok( $Foo, 'attribute_class' );
can_ok( $Foo, 'method_class' );

can_ok( $Foo, 'get_name' );
can_ok( $Foo, 'get_version' );
can_ok( $Foo, 'get_authority' );

can_ok( $Foo, 'find_method' );
can_ok( $Foo, 'get_all_methods' );

can_ok( $Foo, 'find_attribute' );
can_ok( $Foo, 'get_all_attributes' );

is( $Foo->attribute_class, $::Attribute, '... got the expected value of attribute_class');
is( $Foo->method_class, $::Method, '... got the expected value of method_class');

is( $Foo->get_name, 'Foo', '... got the expected value for get_name');
is( $Foo->get_version, '0.01', '... got the expected value for get_version');
is( $Foo->get_authority, 'cpan:STEVAN', '... got the expected value for get_authority');

=pod

role Bar {
    has $bar = 'bar';
    method bar { $bar }
}

=cut

my $Bar = $::Role->new(
    attributes => {
        '$bar' => $::Attribute->new( name => '$bar', initial_value => \'bar' )
    },
    methods => {
        'bar' => $::Method->new( name => 'bar', body => sub { mop::internal::instance::get_data_for('$bar') } )
    }
);

my $method = $Bar->find_method( 'bar' );
ok( $method->isa( $::Method ), '... got the method we expected' );
is( $method->get_name, 'bar', '... got the name of the method we expected');

my $attribute = $Bar->find_attribute( '$bar' );
ok( $attribute->isa( $::Attribute ), '... got the attribute we expected' );
is( $attribute->get_name, '$bar', '... got the name of the attribute we expected');

done_testing;

