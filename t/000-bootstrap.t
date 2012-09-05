#!perl

use strict;
use warnings;

use Test::More;

require mop; mop->import;

ok $::Class,     '... we have the class Class';
ok $::Object,    '... we have the class Object';
ok $::Method,    '... we have the class Method';
ok $::Attribute, '... we have the class Attribute';
ok $::Role,      '... we have the class Role';

# check the simple bootstrapped knot tie-ing

is mop::class_of( $::Object ), $::Class, '... the class of Object is Class';
is mop::class_of( $::Class ), $::Class, '... the class of Class is Class';

ok $::Class->instance_isa( $::Object ), '... class Class is a subclass of Object';
ok $::Class->instance_isa( $::Class ), '... class Class is not a subclass of Class';

ok $::Class->isa( $::Object ), '... class Class is-a Object';
ok $::Class->isa( $::Class ), '... class Class is-a Class';

ok $::Object->instance_isa( $::Object ), '... class Object is not a subclass of Object';
ok !$::Object->instance_isa( $::Class ), '... class Object is not a subclass of Class';

ok $::Object->isa( $::Object ), '... class Object is-a Object';
ok $::Object->isa( $::Class ), '... class Object is-a Class';

# check the role bootstrap knot tie-ing

is mop::class_of( $::Object ), $::Class, '... the class of Role is Class';
ok $::Role->isa( $::Class ), '... class Role is a Class';

# check the other elements

is mop::class_of( $::Method ), $::Class, '... the class of Method is Class';
is mop::class_of( $::Attribute ), $::Class, '... the class of Attribute is Class';

ok $::Method->instance_isa( $::Object ), '... class Method is a subclass of Object';
ok $::Attribute->instance_isa( $::Object ), '... class Attribute is a subclass of Object';

ok $::Method->isa( $::Object ), '... class Method is-a of Object';
ok $::Method->isa( $::Class ), '... class Method is-a of Class';

ok $::Attribute->isa( $::Object ), '... class Attribute is-a of Object';
ok $::Attribute->isa( $::Class ), '... class Attribute is-a of Class';

# check to see that everything is what it is supposed to be ...

is $::Class->name, 'Class', '... got the right name';
is $::Class->version, '0.01', '... got the right version';
is $::Class->authority, 'cpan:STEVAN', '... got the right authority';
is $::Class->superclass, $::Object, '... got the right superclass';
is_deeply $::Class->mro, [ $::Class, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Class->mro };
    is((shift @mro), $::Class, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Class->instance_isa( $super ), '... we are a subclass of class (' . $super->name . ')';
    }
}

foreach my $method ( values %{ $::Class->methods } ) {
    ok $method->isa( $::Method ), '... method (' . $method->name . ') of class Class is a Method object';
    is $::Class->find_method( $method->name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Class->attributes } ) {
    ok $attribute->isa( $::Attribute ), '... attribute (' . $attribute->name . ') of class Class is an Attribute object';
    is $::Class->find_attribute( $attribute->name ), $attribute, '... found the attribute too';
}

is $::Object->name, 'Object', '... got the right name';
is $::Object->version, '0.01', '... got the right version';
is $::Object->authority, 'cpan:STEVAN', '... got the right authority';
is $::Object->superclass, undef, '... got the right superclass';
is_deeply $::Object->mro, [ $::Object ], '... got the right mro';

{
    my @mro = @{ $::Object->mro };
    is((shift @mro), $::Object, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Object->instance_isa( $super ), '... we are a subclass of class (' . $super->name . ')';
    }
}

foreach my $method ( values %{ $::Object->methods } ) {
    ok $method->isa( $::Method ), '... method (' . $method->name . ') of class Object is a Method object';
    is $::Object->find_method( $method->name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Object->attributes } ) {
    ok $attribute->isa( $::Attribute ), '... attribute (' . $attribute->name . ') of class Object is an Attribute object';
    is $::Object->find_attribute( $attribute->name ), $attribute, '... found the attribute too';
}

is $::Method->name, 'Method', '... got the right name';
is $::Method->version, '0.01', '... got the right version';
is $::Method->authority, 'cpan:STEVAN', '... got the right authority';
is $::Method->superclass, $::Object, '... got the right superclass';
is_deeply $::Method->mro, [ $::Method, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Method->mro };
    is((shift @mro), $::Method, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Method->instance_isa( $super ), '... we are a subclass of class (' . $super->name . ')';
    }
}

foreach my $method ( values %{ $::Method->methods } ) {
    ok $method->isa( $::Method ), '... method (' . $method->name . ') of class Method is a Method object';
    is $::Method->find_method( $method->name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Method->attributes } ) {
    ok $attribute->isa( $::Attribute ), '... attribute (' . $attribute->name . ') of class Method is an Attribute object';
    is $::Method->find_attribute( $attribute->name ), $attribute, '... found the attribute too';
}

is $::Attribute->name, 'Attribute', '... got the right name';
is $::Attribute->version, '0.01', '... got the right version';
is $::Attribute->authority, 'cpan:STEVAN', '... got the right authority';
is $::Attribute->superclass, $::Object, '... got the right superclass';
is_deeply $::Attribute->mro, [ $::Attribute, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Attribute->mro };
    is((shift @mro), $::Attribute, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Attribute->instance_isa( $super ), '... we are a subclass of class (' . $super->name . ')';
    }
}

foreach my $method ( values %{ $::Attribute->methods } ) {
    ok $method->isa( $::Method ), '... method (' . $method->name . ') of class Attribute is a Method object';
    is $::Attribute->find_method( $method->name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Attribute->attributes } ) {
    ok $attribute->isa( $::Attribute ), '... attribute (' . $attribute->name . ') of class Attribute is an Attribute object';
    is $::Attribute->find_attribute( $attribute->name ), $attribute, '... found the attribute too';
}

is $::Role->name, 'Role', '... got the right name';
is $::Role->version, '0.01', '... got the right version';
is $::Role->authority, 'cpan:STEVAN', '... got the right authority';
is $::Role->superclass, $::Object, '... got the right superclass';
is_deeply $::Role->mro, [ $::Role, $::Object ], '... got the right mro';

{
    my @mro = @{ $::Role->mro };
    is((shift @mro), $::Role, '... we are the first entry in our mro');
    foreach my $super ( @mro ) {
        ok $::Role->instance_isa( $super ), '... we are a subclass of class (' . $super->name . ')';
    }
}

foreach my $method ( values %{ $::Role->methods } ) {
    ok $method->isa( $::Method ), '... method (' . $method->name . ') of class Role is a Method object';
    is $::Role->find_method( $method->name ), $method, '... found the method too';
}

foreach my $attribute ( values %{ $::Role->attributes } ) {
    ok $attribute->isa( $::Attribute ), '... attribute (' . $attribute->name . ') of class Role is an Attribute object';
    is $::Role->find_attribute( $attribute->name ), $attribute, '... found the attribute too';
}


done_testing;
