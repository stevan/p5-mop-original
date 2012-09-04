#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

=pod

This test immitates the Smalltalk style
parallel metaclass way of doing class
methods.

=cut

# create a meta-class (class to create classes with)
class FooMeta (extends => $::Class) {
    method static_method { 'STATIC' }
}

is mop::class_of( FooMeta ), $::Class, '... got the class we expected';
ok FooMeta->isa( $::Object ), '... FooMeta is an Object';
ok FooMeta->isa( $::Class ), '... FooMeta is a Class';
ok FooMeta->instance_isa( $::Object ), '... FooMeta is a subclass of Object';
ok FooMeta->instance_isa( $::Class ), '... FooMeta is a subclass of Class';

# create a class (using our meta-class)
class Foo (metaclass => FooMeta) {
    method hello            { 'FOO' }
    method hello_from_class { $::CLASS->static_method }
}

is mop::class_of( Foo ), FooMeta, '... got the class we expected';
ok Foo->isa( $::Object ), '... Foo is an Object';
ok Foo->isa( $::Class ), '... Foo is a Class';
ok Foo->isa( FooMeta ), '... Foo is a FooMeta';
ok Foo->instance_isa( $::Object ), '... Foo is a subclass of Object';

is Foo->static_method, 'STATIC', '... called the static method on Foo';

# create an instance ...
my $foo = Foo->new;

is mop::class_of( $foo ), Foo, '... got the class we expected';
ok $foo->isa( Foo ), '... foo is a Foo';
ok $foo->isa( $::Object ), '... foo is an Object';
ok !$foo->isa( $::Class ), '... foo is not a Class';
ok !$foo->isa( FooMeta ), '... foo is not a FooMeta';

like exception { $foo->static_method }, qr/^Can\'t locate object method \"static_method\" via package/, '... got an expection here';

is $foo->hello_from_class, 'STATIC', '... got the class method via the instance however';
is mop::class_of( $foo )->static_method, 'STATIC', '... got access to the class method via the mop::class_of function';
is $foo->hello, 'FOO', '... got the instance method however';

done_testing;