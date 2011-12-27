#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

class Foo {
    has $foo (reader => 'get_foo', writer => 'set_foo');
    has $bar (accessor => 'bar');
    has $baz (predicate => 'has_baz', clearer => 'clear_baz') = 1;
}

{
    isa_ok(Foo, Class::MOPX::Class);
    isa_ok(Foo->find_attribute($_), Class::MOPX::Attribute)
        for qw($foo $bar $baz);
    isa_ok(Foo->find_method($_), Class::MOPX::Method)
        for qw(get_foo set_foo bar has_baz clear_baz);
}

{
    my $foo = Foo->new;
    can_ok($foo, $_)
        for qw(get_foo set_foo bar has_baz clear_baz);

    is($foo->get_foo, undef);
    $foo->set_foo("FOO");
    is($foo->get_foo, "FOO");

    is($foo->bar, undef);
    $foo->bar("BAR");
    is($foo->bar, "BAR");

    ok($foo->has_baz);
    $foo->clear_baz;
    ok(!$foo->has_baz);
}

done_testing;
