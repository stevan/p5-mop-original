#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my @OUTPUT;

BEGIN {

    class WrappedMethod ( extends => $::Method ) {
        method execute ( @args ) {
            push @OUTPUT => "calling " . $self->get_name;
            super( @args );
        }
    }

    class WithWrappedMethods ( extends => $::Class ) {
        method method_class { WrappedMethod() }
    }

}
BEGIN {

    class Foo (metaclass => WithWrappedMethods) {
        method foo { "FOO" }
        method bar { "BAR" }
        method baz { "BAZ" }
    }
}

my $foo = Foo->new;
ok( $foo->isa( Foo ), '... got the expected instance');

is( mop::class_of( Foo ), WithWrappedMethods, '... got the right meta class');
is( Foo->method_class, WrappedMethod, '... got the right method class');

$foo->foo;
$foo->bar;
$foo->baz;

is_deeply(
    \@OUTPUT,
    [
        'calling foo',
        'calling bar',
        'calling baz',
    ],
    '... got the output we expected'
);


done_testing;