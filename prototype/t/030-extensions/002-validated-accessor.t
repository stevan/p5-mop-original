#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use mop;

BEGIN {
    my ($self, $class);

    class 'ValidatedAttribute' => sub {
        extends $::Attribute;
        has( my $validator ) = sub { 1 };

        method get_validator => sub { $validator };
    };
}

BEGIN {
    my ($self, $class);

    class 'ValidatedAccessorMeta' => sub {
        extends $::Class;
        method attribute_class => sub { ValidatedAttribute };

        method 'FINALIZE' => sub {

            foreach my $attribute ( values %{ $self->get_attributes } ) {
                my $name = $attribute->get_name;
                my $validator = $attribute->get_validator;

                my $accessor_name = $name;
                $accessor_name =~ s/^\$//;

                $self->add_method(
                    $::Method->new(
                        name => $accessor_name,
                        body => sub {
                            if (@_) {
                                my $value = shift;
                                die "invalid value '$value' for attribute '$name'"
                                    unless $validator->($value);
                                mop::internal::instance::set_slot_at( $::SELF, $name, \$value );
                            }
                            mop::internal::instance::get_slot_at( $::SELF, $name )
                        }
                    )
                );
            }

            $self->NEXTMETHOD('FINALIZE');
        };
    };

}

BEGIN {

    class 'Foo' => (metaclass => ValidatedAccessorMeta) => sub {
        has( my $bar );
        has( my $baz );
        has( my $age, validator => sub { $_[0] =~ /^\d+$/ } );
    };
}

is Foo->class, ValidatedAccessorMeta, '... Foo has the right metaclass';
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
    is $foo->age, undef, '... there is no value for age';

    is exception { $foo->bar( 100 ) }, undef, '... set the bar value without dying';
    is exception { $foo->baz( 'BAZ' ) }, undef, '... set the baz value without dying';
    is exception { $foo->age( 34 ) }, undef, '... set the age value without dying';

    is $foo->bar, 100, '... and got the expected value for bar';
    is $foo->baz, 'BAZ', '... and got the expected value for bar';
    is $foo->age, 34, '... and got the expected value for age';

    like exception { $foo->age( 'not an int' ) }, qr/invalid value 'not an int' for attribute '\$age'/, '... could not set to a non-int value';

    is $foo->age, 34, '... kept the old value of age';
}

done_testing;

