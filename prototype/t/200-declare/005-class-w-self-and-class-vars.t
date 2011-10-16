#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {
    class Foo {
        method bar { 'BAR' }
        method baz { $self->bar }

        method foobar { $class->get_name }
    }
}

is( Foo->get_name, 'Foo', '... got the name we expected' );
is_deeply( Foo->get_superclasses, [ $::Object ], '... got the superclasses we expected' );

my $foo = Foo->new;
ok($foo->is_a( Foo ), '... got the right instance');
is($foo->baz, 'BAR', '... the $self worked correctly');
is($foo->foobar, 'Foo', '... the $class worked correctly');

done_testing;