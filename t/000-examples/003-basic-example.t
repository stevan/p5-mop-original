#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

role Eq {
    method equal_to;

    method not_equal_to ($other) {
        not $self->equal_to($other);
    }
}

role Comparable ( with => Eq ) {
    method compare;
    method equal_to ($other) {
        $self->compare($other) == 0;
    }

    method greater_than ($other)  {
        $self->compare($other) == 1;
    }

    method less_than  ($other) {
        $self->compare($other) == -1;
    }

    method greater_than_or_equal_to ($other)  {
        $self->greater_than($other) || $self->equal_to($other);
    }

    method less_than_or_equal_to ($other)  {
        $self->less_than($other) || $self->equal_to($other);
    }
}

role Printable {
    method to_string;
}

class US::Currency ( with => [ Comparable, Printable ] ) {
    has $amount = 0;

    method compare ($other) {
        $self->amount <=> $other->amount;
    }

    method to_string {
        sprintf '$%0.2f USD' => $self->amount;
    }
}

done_testing;
