#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

class Foo {
    has $foo (builder => 'build_foo');

    method foo { $foo }

    method build_foo { "FOO" }
}

{
    is(Foo->new->foo, "FOO");
}

done_testing;
