#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

my $Foo = $::Class->new;

{
    local $::CLASS = $Foo;

    BUILD ( $params ) {}
}

my $foo_constructor = $Foo->get_constructor();
ok( $foo_constructor, '... found the BUILD method' );
ok( $foo_constructor->isa( $::Method ), '... it is a proper method');
is($foo_constructor->get_name, 'BUILD', '... got the right name for BUILD');


done_testing;