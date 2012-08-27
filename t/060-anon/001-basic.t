#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

# XXX these keywords are parsed at compile time currently
my $Role;
BEGIN {
$Role = role {
    method inc ($x) { $x + 1 }
};
}

my $Class = class (with => [$Role]) {
    has $num = 2;
    method inc_num { $self->inc($num) }
};

{
    my $obj = $Class->new;
    is($obj->inc_num, 3);
}

{
    my $obj = $Class->new(num => 5);
    is($obj->inc_num, 6);
}

done_testing;
