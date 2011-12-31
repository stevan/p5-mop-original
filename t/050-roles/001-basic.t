#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

role Foo {
    has $bar = 'bar';
    method bar { $bar }
}

=cut

my $Foo = $::Role->new(
    attributes => {
        '$bar' => $::Attribute->new( name => '$bar', initial_value => \'bar' )
    },
    methods => {
        'bar' => $::Method->new( name => 'bar', body => sub { mop::internal::instance::get_data_for('$bar') } )
    }
);

class Baz (with => $Foo) {
    method baz { join ", "  => $self->bar, 'baz' }
}

{
    my $baz = Baz->new;

    ok( Baz->has_method('baz'), '... the Baz class has the baz method' );
    ok( Baz->has_method('bar'), '... the Baz class has the bar method (composed from Foo role)' );

    ok( Baz->has_attribute('$bar'), '... the Baz class has the $bar attribute' );

    ok( $baz->isa( Baz ), '... the object is from class Baz' );
    ok( $baz->isa( $::Object ), '... the object is derived from class Object' );
    is( mop::class_of( $baz ), Baz, '... the class of this object is Baz' );
    ok( $baz->DOES( $Foo ), '... the object also DOES the Foo role')

    can_ok( $baz, 'baz' );
    can_ok( $baz, 'bar' );

    is( $baz->bar, 'bar', '... got the right value from ->bar');
    is( $baz->baz, 'bar, baz', '... got the right value from ->baz');
}

done_testing;