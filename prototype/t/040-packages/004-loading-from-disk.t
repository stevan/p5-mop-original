#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

use Foo::Bar;

my $foo = Foo::Bar->new;
ok( $foo->is_a( Foo::Bar ), '... the object is from class Foo' );
ok( $foo->is_a( $::Object ), '... the object is derived from class Object' );
is( $foo->class, Foo::Bar, '... the class of this object is Foo' );
is( $foo->class->get_name, 'Foo::Bar', '... got the correct (fully qualified) name of the class');

done_testing;
