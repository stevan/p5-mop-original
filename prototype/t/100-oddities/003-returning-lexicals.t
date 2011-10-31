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

my $bar = Foo->new;
ok( $bar->isa( Foo ), '... got the instance we expected');

my $foo_func = $foo->self_func;
is( ref $foo_func, 'CODE', '... got the code ref we expected');

my $bar_func = $bar->self_func;
is( ref $bar_func, 'CODE', '... got the code ref we expected');

is( $foo_func->(), $foo, '... and the function returns the $self we expected');
is( $bar_func->(), $bar, '... and the function returns the $self we expected');

done_testing;