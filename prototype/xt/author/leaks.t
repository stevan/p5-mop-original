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
    state $i = 0;
    eval <<CLASS;
class Foo$i {
    has \$foo;
    method foo { \$foo }
}
CLASS
    $i++;
};

done_testing;
