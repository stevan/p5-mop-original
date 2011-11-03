#!/usr/bin/env perl
use strict;
use warnings;
use 5.014;
use Test::More;
BEGIN {
    eval { require Test::LeakTrace; 1 }
        or plan skip_all => "This test requires Test::LeakTrace";
    Test::LeakTrace->import;
}

use mop;

local $TODO = "we're pretty leaky";

no_leaks_ok {
    local $SIG{__WARN__} = sub {
        return if $_[0] =~ /Constant subroutine main::Foo redefined/;
        warn $_[0];
    };
    eval <<CLASS;
class Foo {
    has \$foo;
    method foo { \$foo }
}
CLASS
};

done_testing;
