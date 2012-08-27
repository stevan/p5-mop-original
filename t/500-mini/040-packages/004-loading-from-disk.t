#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';

use Foo::Bar;

my $foo = Foo::Bar->new;
ok( $foo->isa( Foo::Bar ), '... the object is from class Foo' );
is( Foo::Bar->get_name, 'Foo::Bar', '... got the correct (fully qualified) name of the class');

done_testing;
