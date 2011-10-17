use strict;
use warnings;
use mop;

class Test::Builder::TestPlan {
    has $expect;

    BUILD {
        die "Invalid or missing plan" unless defined $expect;
    }

    method header { "1..$expect" }

    method footer ( $run ) {
        return '' if $run == $expect;
        return "Expected $expect but ran $run";
    }
}

class Test::Builder::NullPlan {
    method header { '' }
    method footer ( $run ) { "1..$run" }
}

1;