#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {
    class Foo {
        method foo ($a) {
            $mop::internal::DEBUG = 1;
            my $id = mop::uuid_of( $self );
            if ( ref $a ne "" ) {
                $a->foo("x");
                is( $id, mop::uuid_of( $self ), '... this should be the same ref');
                $mop::internal::DEBUG = 0;
            }
        }
    }
}

my $foo = Foo->new;
ok( $foo->isa( Foo() ), '... got the instance we expected');

my $bar = Foo->new;
ok( $bar->isa( Foo() ), '... got the instance we expected');

$foo->foo($bar);

done_testing;