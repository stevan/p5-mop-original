#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

class Foo {
    has $foo (init_arg => 'bar');
    method foo { $foo }
}

{
    is(Foo->new(foo => 1)->foo, undef);
    is(Foo->new(bar => 1)->foo, 1);
}

done_testing;
