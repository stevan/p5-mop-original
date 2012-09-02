#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

{
    my $method = $::Method->new(
        name => 'foo',
        body => sub { "FOO" },
    );
    my $attribute = $::Attribute->new(
        name          => '$foo',
        initial_value => \sub { "OOF" },
    );

    my $Foo = do {
        my $c = $::Class->new(name => 'Foo');
        $c->add_method($method->clone);
        $c->add_attribute($attribute->clone);
        $c->FINALIZE;
        $c
    };
    my $Bar = do {
        my $c = $::Class->new(name => 'Bar');
        $c->add_method($method->clone);
        $c->add_attribute($attribute->clone);
        $c->FINALIZE;
        $c
    };

    my $foo = $Foo->new;
    can_ok($foo, 'foo');
    is($foo->foo, 'FOO');
    is(${ mop::internal::instance::get_slot_at($foo, '$foo') }, 'OOF');

    my $bar = $Bar->new;
    can_ok($bar, 'foo');
    is($bar->foo, 'FOO');
    is(${ mop::internal::instance::get_slot_at($bar, '$foo') }, 'OOF');

    is($Foo->find_method('foo')->get_body, $method->get_body);
    is($Bar->find_method('foo')->get_body, $method->get_body);
    is($Foo->find_method('foo')->get_body, $Bar->find_method('foo')->get_body);

    isnt($Foo->find_method('foo'), $method);
    isnt($Bar->find_method('foo'), $method);
    isnt($Foo->find_method('foo'), $Bar->find_method('foo'));

    isnt($Foo->find_attribute('$foo'), $attribute);
    isnt($Bar->find_attribute('$foo'), $attribute);
    isnt($Foo->find_attribute('$foo'), $Bar->find_attribute('$foo'));
}

{
    my $method = $::Method->new(
        name => 'bar',
        body => sub { "FOO" },
    );
    my $attribute = $::Attribute->new(
        name          => '$bar',
        initial_value => \sub { "OOF" },
    );

    my $Foo = do {
        my $c = $::Class->new(name => 'Foo');
        $c->add_method($method->clone(name => 'foo'));
        $c->add_attribute($attribute->clone(name => '$foo'));
        $c->FINALIZE;
        $c
    };
    my $Bar = do {
        my $c = $::Class->new(name => 'Bar');
        $c->add_method($method->clone(body => sub { "BAR" }));
        $c->add_attribute($attribute->clone(initial_value => \sub { "RAB" }));
        $c->FINALIZE;
        $c
    };

    my $foo = $Foo->new;
    can_ok($foo, 'foo');
    ok(!$foo->can('bar'));
    is($foo->foo, 'FOO');
    is(${ mop::internal::instance::get_slot_at($foo, '$foo') }, 'OOF');
    is(${ mop::internal::instance::get_slot_at($foo, '$bar') }, undef);

    my $bar = $Bar->new;
    ok(!$bar->can('foo'));
    can_ok($bar, 'bar');
    is($bar->bar, 'BAR');
    is(${ mop::internal::instance::get_slot_at($bar, '$foo') }, undef);
    is(${ mop::internal::instance::get_slot_at($bar, '$bar') }, 'RAB');

    is($Foo->find_method('foo')->get_body, $method->get_body);
    isnt($Bar->find_method('bar')->get_body, $method->get_body);
    isnt($Foo->find_method('foo')->get_body, $Bar->find_method('bar')->get_body);

    isnt($Foo->find_method('foo'), $method);
    isnt($Bar->find_method('bar'), $method);
    isnt($Foo->find_method('foo'), $Bar->find_method('bar'));

    isnt($Foo->find_attribute('$foo'), $attribute);
    isnt($Bar->find_attribute('$bar'), $attribute);
    isnt($Foo->find_attribute('$foo'), $Bar->find_attribute('$bar'));
}

done_testing;
