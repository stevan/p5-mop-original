#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {
    method foo ($a) {
        my $id = mop::uuid_of( $self );
        if ( ref $a ne "" ) {
            $a->foo("x");
            is( $id, mop::uuid_of( $self ), '... this should be the same ref');
        }
        is( $id, mop::uuid_of( $self ), '... this should be the same ref');
    }
}

my $foo = Foo->new;
ok( $foo->isa( Foo ), '... got the instance we expected');

my $bar = Foo->new;
ok( $bar->isa( Foo ), '... got the instance we expected');

$foo->foo($bar);

done_testing;