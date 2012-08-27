#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Dumper;

use mop::mini;

class Foo {
    has $bar = 10;
    method bar { $bar }
}

{
    my $foo = Foo->new;
    ok( $foo->isa( Foo ), '... $foo is a Foo' );
    is( $foo->bar, 10, '... got the right value' );
}

{
    my $foo = Foo->new( bar => 20 );
    ok( $foo->isa( Foo ), '... $foo is a Foo' );
    is( $foo->bar, 20, '... got the right value' );
}

class Bar (extends => Foo) {
    has $baz = 100;
    method baz { $baz }
    method gorch { $self->bar + $self->baz }
}

{
    my $bar = Bar->new;
    ok( $bar->isa( Bar ), '... $bar is a Bar' );
    ok( $bar->isa( Foo ), '... $bar is a Foo' );
    is( $bar->bar, 10, '... got the right value' );
    is( $bar->baz, 100, '... got the right value' );
    is( $bar->gorch, 110, '... got the right value' );
}

{
    my $bar = Bar->new( bar => 20, baz => 200 );
    ok( $bar->isa( Bar ), '... $bar is a Bar' );
    ok( $bar->isa( Foo ), '... $bar is a Foo' );
    is( $bar->bar, 20, '... got the right value' );
    is( $bar->baz, 200, '... got the right value' );
    is( $bar->gorch, 220, '... got the right value' );
}



done_testing;
