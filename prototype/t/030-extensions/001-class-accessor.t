#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use mop;

BEGIN {

    class ClassAccessorMeta (extends => $::Class) {
        method FINALIZE {

            foreach my $attribute ( values %{ $self->get_attributes } ) {
                my $name = $attribute->get_name;
                my $accessor_name = $name;
                $accessor_name =~ s/^\$//;

                $self->add_method(
                    $::Method->new(
                        name => $accessor_name,
                        body => sub {
                            mop::internal::instance::set_slot_at( $::SELF, $name, \(shift) ) if @_;
                            mop::internal::instance::get_slot_at( $::SELF, $name )
                        }
                    )
                );
            }

            $self->NEXTMETHOD('FINALIZE');
        }
    }

}

BEGIN {

    class Foo (metaclass => ClassAccessorMeta) {
        has $bar;
        has $baz;
    };
}

is Foo->class, ClassAccessorMeta, '... Foo has the right metaclass';
ok Foo->is_subclass_of( $::Object ), '... Foo is a subtype of Object';
ok Foo->find_method('bar'), '... the bar method was generated for us';
ok Foo->find_method('baz'), '... the baz method was generated for us';

{
    my $foo = Foo->new;
    is $foo->class, Foo, '... we are an instance of Foo';
    ok $foo->is_a( Foo ), '... we is-a Foo';
    ok $foo->is_a( $::Object ), '... we is-a Object';

    is $foo->bar, undef, '... there is no value for bar';
    is $foo->baz, undef, '... there is no value for baz';

    is exception { $foo->bar( 100 ) }, undef, '... set the bar value without dying';
    is exception { $foo->baz( 'BAZ' ) }, undef, '... set the baz value without dying';

    is $foo->bar, 100, '... and got the expected value for bar';
    is $foo->baz, 'BAZ', '... and got the expected value for bar';
}

{
    my $foo = Foo->new( bar => 100, baz => 'BAZ' );
    is $foo->class, Foo, '... we are an instance of Foo';
    ok $foo->is_a( Foo ), '... we is-a Foo';
    ok $foo->is_a( $::Object ), '... we is-a Object';

    is $foo->bar, 100, '... and got the expected value for bar';
    is $foo->baz, 'BAZ', '... and got the expected value for bar';

    is exception { $foo->bar( 300 ) }, undef, '... set the bar value without dying';
    is exception { $foo->baz( 'baz' ) }, undef, '... set the baz value without dying';

    is $foo->bar, 300, '... and got the expected value for bar';
    is $foo->baz, 'baz', '... and got the expected value for bar';
}



done_testing;