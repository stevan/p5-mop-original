#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use mop;

use lib 't/400-yapc-eu-examples/lib/';

use GuardedAttributeClass;

class Foo (metaclass => GuardedAttributeClass) {
    has $bar;
    has $baz;
    has $age (guard => sub { $_[0] =~ /^\d+$/ });
}


my $foo = Foo->new;


done_testing;