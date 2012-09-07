#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

class Container {
    has %things;

    method things { \%things }

    method add_thing ( $name, $thing ) {
        $things{ $name } = $thing;
    }

    method delete_thing ( $name ) {
        delete $things{ $name }
    }
}

my $c = Container->new( things => { foo => 1 } );
ok($c->isa(Container), '... isa Container');

is_deeply($c->things, { foo => 1 }, '... got the value we expected for things');

is(exception {
    $c->add_thing( bar => 10 );
}, undef, '... add_thing succeded');

is_deeply($c->things, { foo => 1, bar => 10 }, '... got the value we expected for things');

is(exception {
    $c->delete_thing( 'foo' );
}, undef, '... delete_thing succeded');

is_deeply($c->things, { bar => 10 }, '... got the value we expected for things');

done_testing;

