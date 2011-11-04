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
}

{
    my $foo = Foo->new;
    is(exception { $foo->foo(23) }, undef,
       "23 passes the constraint");
    like(
        exception { $foo->foo("bar") },
        qr/Type constraint Int failed with value bar/,
        "'bar' doesn't pass the constraint"
    );
}

done_testing;
