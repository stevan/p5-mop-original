#!perl

use strict;
use warnings;

use Test::More;

use mop;

ok $::Class,     '... we have the class Class';
ok $::Object,    '... we have the class Object';
ok $::Method,    '... we have the class Method';
ok $::Attribute, '... we have the class Attribute';

# check the simple bootstrapped knot tie-ing

is $::Object->class, $::Class, '... the class of Object is Class';
is $::Class->class, $::Class, '... the class of Class is Class';

ok $::Class->is_subclass_of( $::Object ), '... class Class is a subclass of Object';
ok !$::Class->is_subclass_of( $::Class ), '... class Class is not a subclass of Class';

ok $::Class->is_a( $::Object ), '... class Class is-a Object';
ok $::Class->is_a( $::Class ), '... class Class is-a Class';

ok !$::Object->is_subclass_of( $::Object ), '... class Object is not a subclass of Object';
ok !$::Object->is_subclass_of( $::Class ), '... class Object is not a subclass of Class';

ok $::Object->is_a( $::Object ), '... class Object is-a Object';
ok $::Object->is_a( $::Class ), '... class Object is-a Class';

# check the other elements

is $::Method->class, $::Class, '... the class of Method is Class';
is $::Attribute->class, $::Class, '... the class of Attribute is Class';

ok $::Method->is_subclass_of( $::Object ), '... class Method is a subclass of Object';
ok $::Attribute->is_subclass_of( $::Object ), '... class Attribute is a subclass of Object';

ok $::Method->is_a( $::Object ), '... class Method is-a of Object';
ok $::Method->is_a( $::Class ), '... class Method is-a of Class';

ok $::Attribute->is_a( $::Object ), '... class Attribute is-a of Object';
ok $::Attribute->is_a( $::Class ), '... class Attribute is-a of Class';

# check to see that everything is what it is supposed to be ...

foreach my $method ( values %{ $::Class->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Class is a Method object';
}

foreach my $attribute ( values %{ $::Class->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Class is an Attribute object';
}

foreach my $method ( values %{ $::Object->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Object is a Method object';
}

foreach my $attribute ( values %{ $::Object->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Object is an Attribute object';
}

foreach my $method ( values %{ $::Method->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Method is a Method object';
}

foreach my $attribute ( values %{ $::Method->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Method is an Attribute object';
}

foreach my $method ( values %{ $::Attribute->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Attribute is a Method object';
}

foreach my $attribute ( values %{ $::Attribute->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Attribute is an Attribute object';
}

done_testing;