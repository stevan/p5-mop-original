#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

class Queue {
    has @elements;

    method elements { \@elements }

    method add ( $element ) { push @elements => $element }

    method remove { pop @elements }
}

my $c = Queue->new( elements => [ 1, 2, 3 ] );
ok($c->isa(Queue), '... isa Queue');

is_deeply($c->elements, [ 1, 2, 3 ], '... got the value we expected for elements');

is(exception { $c->add( 4 ) }, undef, '... add succeded');

is_deeply($c->elements, [ 1, 2, 3, 4 ], '... got the value we expected for elements');

is(exception { $c->remove }, undef, '... remove succeded');

is_deeply($c->elements, [ 1, 2, 3 ], '... got the value we expected for elements');

is(exception { $c->remove }, undef, '... remove succeded');

is_deeply($c->elements, [ 1, 2 ], '... got the value we expected for elements');

done_testing;

