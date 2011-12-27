#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/ext/Class-MOPX';

use Class::MOPX;
use Class::MOPX::Types;

class Foo {
    has $foo (
        is  => 'rw',
        isa => T->type('Int'),
    );
    has $bar (
        reader => 'get_bar',
        writer => 'set_bar',
        isa    => T->type('ArrayRef'),
    );
}

{
    my $foo = Foo->new;
    is(exception { $foo->foo(23) }, undef,
       "23 passes the constraint");
    is($foo->foo, 23);
    like(
        exception { $foo->foo("bar") },
        qr/Type constraint Int failed with value bar/,
        "'bar' doesn't pass the constraint"
    );
    is($foo->foo, 23);
}

{
    my $foo = Foo->new;
    my $aref = [];
    is(exception { $foo->set_bar($aref) }, undef,
       "arrayref passes the constraint");
    is($foo->get_bar, $aref);
    like(
        exception { $foo->set_bar("bar") },
        qr/Type constraint ArrayRef failed with value bar/,
        "'bar' doesn't pass the constraint"
    );
    is($foo->get_bar, $aref);
}

{
    my $foo;
    is(exception { $foo = Foo->new(foo => 23) }, undef,
       "constraints in constructors work");
    is($foo->foo, 23);
    like(
        exception { $foo = Foo->new(foo => "FOO") },
        qr/Type constraint Int failed with value FOO/,
        "constraints in constructors work"
    );

    my $aref = [];
    is(exception { $foo = Foo->new(bar => $aref) }, undef,
       "constraints in constructors work");
    is($foo->get_bar, $aref);
    like(
        exception { $foo = Foo->new(bar => "FOO") },
        qr/Type constraint ArrayRef failed with value FOO/,
        "constraints in constructors work"
    );
}

class Bar {
    has $foo (
        is      => 'ro',
        isa     => T->type('Int'),
        lazy    => 1,
        builder => 'build_foo'
    );
    method build_foo { "FOO" }

    has $bar (
        is      => 'rw',
        isa     => T->type('Int'),
        lazy    => 1,
        builder => 'build_bar'
    );
    method build_bar { "BAR" }
}

{
    my $bar = Bar->new;
    like(
        exception { $bar->foo },
        qr/Type constraint Int failed with value FOO/,
        "lazy defaults also fail"
    );
    like(
        exception { $bar->bar },
        qr/Type constraint Int failed with value BAR/,
        "lazy defaults also fail"
    );
}

done_testing;
