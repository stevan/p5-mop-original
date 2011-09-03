#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;
use mop::internal::attribute::set;
use mop::internal::method::set;

=pod

This test immitates the Smalltalk style
parallel metaclass way of doing class
methods.

=cut

# create a meta-class (class to create classes with)
my $FooMeta = $::Class->new(
    superclasses => [ $::Class ],
    methods      => mop::internal::method::set::create(
        mop::internal::method::create( name => 'static_method', body => sub { 'STATIC' } )
    )
);

is $FooMeta->class, $::Class, '... got the class we expected';
ok $FooMeta->is_a( $::Object ), '... FooMeta is an Object';
ok $FooMeta->is_a( $::Class ), '... FooMeta is a Class';
ok $FooMeta->is_subclass_of( $::Object ), '... FooMeta is a subclass of Object';
ok $FooMeta->is_subclass_of( $::Class ), '... FooMeta is a subclass of Class';

# create a class (using our meta-class)
my $Foo = $FooMeta->new(
    superclasses => [ $::Object ],
    methods      => mop::internal::method::set::create(
        mop::internal::method::create( name => 'hello', body => sub { 'FOO' } )
    )
);

is $Foo->class, $FooMeta, '... got the class we expected';
ok $Foo->is_a( $::Object ), '... Foo is an Object';
ok $Foo->is_a( $::Class ), '... Foo is a Class';
ok $Foo->is_a( $FooMeta ), '... Foo is a FooMeta';
ok $Foo->is_subclass_of( $::Object ), '... Foo is a subclass of Object';

is $Foo->static_method, 'STATIC', '... called the static method on Foo';

# create an instance ...
my $foo = $Foo->new;

is $foo->class, $Foo, '... got the class we expected';
ok $foo->is_a( $Foo ), '... foo is a Foo';
ok $foo->is_a( $::Object ), '... foo is an Object';
ok !$foo->is_a( $::Class ), '... foo is not a Class';
ok !$foo->is_a( $FooMeta ), '... foo is not a FooMeta';

like exception { $foo->static_method }, qr/^Could not find method \'static_method\'/, '... got an expection here';

is $foo->hello, 'FOO', '... got the instance method however';


done_testing;