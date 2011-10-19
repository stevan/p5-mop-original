#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

=cut

BEGIN {
    role FooRole {
        has $foo_role = 10;
        method foo_role { $foo_role }
        method bar { "BAR role" }
    }
    class Foo (with => [ FooRole() ]) {
        has $foo = 20;
        method foo { $foo }
        method bar { "BAR class" }
    }
}

{
    my $foo = Foo->new;
    ok($foo->does(FooRole));

    is($foo->foo, 20);
    is($foo->foo_role, 10);
    is($foo->bar, "BAR class");
}

{
    my $foo = Foo->new(foo => 5, foo_role => 6);
    is($foo->foo, 5);
    is($foo->foo_role, 6);
}

done_testing;
