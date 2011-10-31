#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

Sometimes you might not want to
actually declare the enclosing
package. And you shouldn't have
to. But just as with other things
it should create the namespace
for you automagically.

=cut

class Foo::Bar {}

my $foo = Foo::Bar->new;
ok( $foo->is_a( Foo::Bar ), '... the object is from class Foo' );
ok( $foo->is_a( $::Object ), '... the object is derived from class Object' );
is( $foo->class, Foo::Bar, '... the class of this object is Foo' );
is( $foo->class->get_name, 'Foo::Bar', '... got the correct (fully qualified) name of the class');
like( "$foo", qr/^Foo::Bar/, '... object stringification includes fully qualified class name' );

done_testing;
