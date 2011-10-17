use strict;
use warnings;
use mop;

use Test::Builder::Test;
use Test::Builder::Output;
use Test::Builder::TestPlan;

class Test::Builder {

    has $output;
    has $testplan;
    has $results = []

    BUILD {
        $output = Test::Builder::Output->new;
    }

    DEMOLISH {
        my $footer = $testplan->footer( scalar @$results );
        $output->write( $footer ) if $footer;
    }

    method get_test_number { (scalar @$results) + 1 }

    method plan ( $explanation, $tests ) {
        die "Plan already set" if $testplan;

        if ( $tests ) {
            $testplan = Test::Builder::TestPlan->new( expect => $tests );
        }
        elsif ( $explanation eq 'no_plan' ) {
            $testplan = Test::Builder::NullPlan->new;
        }
        else {
            die "Unknown plan";
        }

        $output->write( $testplan->header );
    }

}