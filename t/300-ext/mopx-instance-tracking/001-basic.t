#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/mopx-instance-tracking';

use mop;
use mopx::instance::tracking;

class Foo {
}

sub is_instances {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply(
        [ sort { $a <=> $b } Foo->instances ],
        [ sort { $a <=> $b } @_ ]
    );
}

my $foo = Foo->new();
is_instances($foo);

do {
    my $bar = Foo->new();
    is_instances($foo, $bar);
};

is_instances($foo);

done_testing();

