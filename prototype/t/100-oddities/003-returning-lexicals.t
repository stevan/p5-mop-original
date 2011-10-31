#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {
    class Foo {
        method self_func () {
            return sub { 1; $self }
        }
    }
}

my $foo = Foo->new;
ok( $foo->isa( Foo ), '... got the instance we expected');

my $func = $foo->self_func;
is( ref $func, 'CODE', '... got the code ref we expected');

is( $func->(), $foo, '... and the function returns the $self we expected');

done_testing;