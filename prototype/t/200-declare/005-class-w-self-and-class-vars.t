#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {
    method bar { 'BAR' }
    method baz { $self->bar }

    method foobar { $class->name }
}

is( Foo->name, 'Foo', '... got the name we expected' );
is(Foo->superclass, $::Object, '... got the superclass we expected');

my $foo = Foo->new;
ok($foo->isa( Foo ), '... got the right instance');
is($foo->baz, 'BAR', '... the $self worked correctly');
is($foo->foobar, 'Foo', '... the $class worked correctly');

done_testing;