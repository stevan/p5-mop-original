#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

class Foo {
    has $foo (is => 'ro');
}

{
    my $foo = Foo->new(foo => "FOO");
    can_ok($foo, 'foo');
    is($foo->foo, "FOO");
}

done_testing;
