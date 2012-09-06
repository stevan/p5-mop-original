#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Foo::Bar;

my $foo = Foo::Bar->new;
ok( $foo->isa( Foo::Bar ), '... the object is from class Foo' );
SKIP: { skip "Requires the full mop", 1 if $ENV{PERL_MOP_MINI}; $::Object = $::Object;
ok( $foo->isa( $::Object ), '... the object is derived from class Object' );
}
is( mop::class_of( $foo ), Foo::Bar, '... the class of this object is Foo' );
SKIP: { skip "Requires the full mop", 1 if $ENV{PERL_MOP_MINI};
is( mop::class_of( $foo )->name, 'Foo::Bar', '... got the correct (fully qualified) name of the class');
}

done_testing;
