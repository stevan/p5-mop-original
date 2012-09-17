#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

class Foo {}
class Foo::Bar {}
class Foo::Bar::Baz {}
class Foo::Bar::Baz::Gorch {}

test_object( Foo->new,                  'Foo'                  => Foo );
test_object( Foo::Bar->new,             'Foo::Bar'             => Foo::Bar );
test_object( Foo::Bar::Baz->new,        'Foo::Bar::Baz'        => Foo::Bar::Baz );
test_object( Foo::Bar::Baz::Gorch->new, 'Foo::Bar::Baz::Gorch' => Foo::Bar::Baz::Gorch );

done_testing;

sub test_object {
    my $object     = shift;
    my $class_name = shift;
    my $class      = shift;

    ok( $object->isa( $class ), '... the object is from class ' . $class_name );
    SKIP: { skip "Requires the full mop", 1 if $ENV{PERL_MOP_MINI};
        ok( $object->isa( $::Object ), '... the object is derived from class Object' );
    }
    is( mop::class_of( $object ), $class, '... the class of this object is ' . $class_name );
    SKIP: { skip "Requires the full mop", 1 if $ENV{PERL_MOP_MINI};
        is( mop::class_of( $object )->name, $class_name, '... got the correct (fully qualified) name of the class');
    }
    like( "$object", qr/^$class_name/, '... object stringification includes fully qualified class name' );
}