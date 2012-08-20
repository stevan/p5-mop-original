#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Devel::StackTrace; 1 }
    or plan skip_all => "Devel::StackTrace is required for this test";
}

use mop;

use lib 't/400-yapc-eu-examples/lib/';

use Throwable;

sub foo { Throwable->new( message => "HELLO" )->throw }
sub bar { foo() }

eval { bar };
my $e = $@;

ok( $e->isa( Throwable ), '... the exception is a Throwable object' );

is( $e->message, 'HELLO', '... got the exception' );

isa_ok( $e->stack_trace, 'Devel::StackTrace' );

my $file = __FILE__;
$file =~ s/^\.\///;

is(
    $e->stack_trace->as_string,
    qq[Trace begun at $file line 20
main::bar at $file line 22
eval {...} at $file line 22
],
    '... got the exception'
);

done_testing;

