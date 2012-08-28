#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use mop;
#BEGIN { $SIG{__DIE__} = \&Carp::confess }

role FooRole (version => 0.01) {
}

my $foo_role = FooRole;
isa_ok($foo_role, $::Role);
isa_ok($foo_role, $::Object);

is($foo_role->get_name, 'FooRole', '... got the right name of FooRole');
is($foo_role->get_version, '0.01', '... got the right version of FooRole');

$foo_role->add_method($::Method->new( name => 'foo', body => sub { 'FooRole::foo' } ));

# methods ...
TODO: {
    todo_skip 'No idea if has_method, get_method and get_method_list will be part of the mop', 4;
    ok($foo_role->has_method('foo'), '... FooRole has the foo method');
    is($foo_role->get_method('foo')->body, \&FooRole::foo, '... FooRole got the foo method');
    isa_ok($foo_role->get_method('foo'), 'Moose::Meta::Role::Method');
    is_deeply(
        [ $foo_role->get_method_list() ],
        [ 'foo' ],
        '... got the right method list');
}

{
    my $methods = $foo_role->get_all_methods;
    is_deeply([keys %$methods], ['foo'], '... FooRole has the foo method');
}

# attributes ...
TODO: {
    todo_skip 'No idea if get_attribute_list and has_attribute will be part of the mop', 2;
    is_deeply(
        [ $foo_role->get_attribute_list() ],
        [],
        '... got the right attribute list');
    ok(!$foo_role->has_attribute('bar'), '... FooRole does not have the bar attribute');
}

{
    is( exception {
        $foo_role->add_attribute($::Attribute->new(name => 'bar' => is => 'rw', isa => 'Foo'));
    }, undef, '... added the bar attribute okay with mop api' );

    local $TODO = 'Cannot add attribute with moose syntax';
    is( exception {
        $foo_role->add_attribute('bar' => (is => 'rw', isa => 'Foo'));
    }, undef, '... added the bar attribute okay with moose api' );
}

{
    my $attrs = $foo_role->get_all_attributes; # $foo_role->get_attribute_list
    my $bar = $attrs->{bar};
    is_deeply([keys %$attrs], ['bar'], 'FooRole does have the bar attribute');

    is($bar->get_name, 'bar', 'attribute bar has the name... wait for it... "bar"!');
    is($bar->get_initial_value, undef, 'attribute bar has no initial value');

    local $TODO = 'original_options does not exist';
    is(exception { $bar->original_options }, undef, '... get original_options with moose api' );

    local $TODO = 'is=>rw does currently not do anything';
    ok(eval { $bar->reader->isa($::Method) }, 'is=>rw result in a reader');
    ok(eval { $bar->writer->isa($::Method) }, 'is=>rw result in a writer');

    local $TODO = 'isa=>Foo does currently not do anything';
    ok(eval { $bar->type_constraint->isa($::TypeWhatever) }, 'isa=>Foo results in a typeconstraint');
}

# NOTE! This is just half of the original moose test. The rest of the tests
# require methods which are not yet defined.

done_testing;
