#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

role Foo {
    has $foo = 1;
    method foo { $foo }
}

class Bar (with => [Foo]) {
    method bar { $self->foo + 1 }
}

TODO: { todo_skip "role application is broken", 1 if $ENV{PERL_MOP_MINI};
is(Bar->new->bar, 2);
}

done_testing;
