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

is $::Class->get_name, 'Class', '... got the right name';
is $::Class->get_version, '0.01', '... got the right version';
is $::Class->get_authority, 'cpan:STEVAN', '... got the right authority';
is_deeply $::Class->get_superclasses, [ $::Object ], '... got the right superclasses';
is_deeply $::Class->get_mro, [ $::Class, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Class->get_mro };
    is((shift @mro), $::Class, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Class->is_subclass_of( $super ), '... we are a subclass of class (' . $super->get_name . ')';
    }
}

foreach my $method ( values %{ $::Class->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Class is a Method object';
    is $::Class->find_method( $method->get_name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Class->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Class is an Attribute object';
}

is $::Object->get_name, 'Object', '... got the right name';
is $::Object->get_version, '0.01', '... got the right version';
is $::Object->get_authority, 'cpan:STEVAN', '... got the right authority';
is_deeply $::Object->get_superclasses, [], '... got the right superclasses';
is_deeply $::Object->get_mro, [ $::Object ], '... got the right mro';

{
    my @mro = @{ $::Object->get_mro };
    is((shift @mro), $::Object, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Object->is_subclass_of( $super ), '... we are a subclass of class (' . $super->get_name . ')';
    }
}

foreach my $method ( values %{ $::Object->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Object is a Method object';
    is $::Object->find_method( $method->get_name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Object->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Object is an Attribute object';
}

is $::Method->get_name, 'Method', '... got the right name';
is $::Method->get_version, '0.01', '... got the right version';
is $::Method->get_authority, 'cpan:STEVAN', '... got the right authority';
is_deeply $::Method->get_superclasses, [ $::Object ], '... got the right superclasses';
is_deeply $::Method->get_mro, [ $::Method, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Method->get_mro };
    is((shift @mro), $::Method, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Method->is_subclass_of( $super ), '... we are a subclass of class (' . $super->get_name . ')';
    }
}

foreach my $method ( values %{ $::Method->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Method is a Method object';
    is $::Method->find_method( $method->get_name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Method->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Method is an Attribute object';
}

is $::Attribute->get_name, 'Attribute', '... got the right name';
is $::Attribute->get_version, '0.01', '... got the right version';
is $::Attribute->get_authority, 'cpan:STEVAN', '... got the right authority';
is_deeply $::Attribute->get_superclasses, [ $::Object ], '... got the right superclasses';
is_deeply $::Attribute->get_mro, [ $::Attribute, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Attribute->get_mro };
    is((shift @mro), $::Attribute, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Attribute->is_subclass_of( $super ), '... we are a subclass of class (' . $super->get_name . ')';
    }
}

foreach my $method ( values %{ $::Attribute->get_methods } ) {
    ok $method->is_a( $::Method ), '... method (' . $method->get_name . ') of class Attribute is a Method object';
    is $::Attribute->find_method( $method->get_name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Attribute->get_attributes } ) {
    ok $attribute->is_a( $::Attribute ), '... attribute (' . $attribute->get_name . ') of class Attribute is an Attribute object';
}

done_testing;