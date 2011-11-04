#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

class Foo {
    has $foo (is => 'ro', required => 1);
}

{
    my $foo;
    like(
        exception { $foo = Foo->new },
        qr/Attribute \$foo is required/,
        "required attributes must be provided"
    );
    is(exception { $foo = Foo->new(foo => 1) }, undef,
       "object creation works if required parameters are fulfilled");
    is($foo->foo, 1);
}

class Bar {
    has $foo (is => 'ro', required => 1) = 23;
}

{
    my $bar;
    is(exception { $bar = Bar->new }, undef,
       "defaults fulfill requirements");
    is($bar->foo, 23);
}

class Baz {
    has $foo (is => 'ro', required => 1, builder => 'build_foo');
    method build_foo { "FOO" }
}

{
    my $baz;
    is(exception { $baz = Baz->new }, undef,
       "builders fulfill requirements");
    is($baz->foo, "FOO");
}

done_testing;
