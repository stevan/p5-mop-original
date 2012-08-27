#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop::mini;

BEGIN {
    class Foo {
        method foo ($a) {
            my $id = $self;
            if ( ref $a ne "" ) {
                $a->foo("x");
                is( $id, $self, '... this should be the same ref');
            }
            is( $id, $self, '... this should be the same ref');
        }
    }
}

my $foo = Foo->new;
my $bar = Foo->new;

$foo->foo($bar);

done_testing;
