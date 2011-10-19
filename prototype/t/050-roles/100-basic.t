#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

=cut

BEGIN {
    role FooRole {}
    class Foo (with => [ FooRole() ]) {}
}

my $foo = Foo->new;
ok($foo->does(FooRole));

done_testing;
