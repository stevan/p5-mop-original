#!/usr/bin/env perl
# Source: moose.git/t/roles/create_role_subclass.t
use strict;
use warnings;
use Test::More;
use mop;

class My::Meta::Role (extends => $::Role) {
    has $test_serial = 1; # is => 'ro', isa => 'Int',
    method test_serial { $test_serial }
}

my $role = My::Meta::Role->new;

diag "isa_ok() does not seem to work";
ok($role->isa($::Role), 'My::Meta::Role inherit from $::Role');
is($role->test_serial, 1, "default value for the serial attribute");

my $nine_role = My::Meta::Role->new(test_serial => 9);
is($nine_role->test_serial, 9, "parameter value for the serial attribute");

done_testing;
