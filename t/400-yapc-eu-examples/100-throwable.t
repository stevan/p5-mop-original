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

class MyError ( with => [Throwable] ) {}

sub foo { MyError->new( message => "HELLO" )->throw }
sub bar { foo() }

eval { bar };
my $e = $@;

ok( $e->does( Throwable ), '... the exception does the Throwable role' );
ok( $e->isa( MyError ), '... the exception is a MyError object' );

is( $e->message, 'HELLO', '... got the exception' );

isa_ok( $e->stack_trace, 'Devel::StackTrace' );

my $file = __FILE__;
$file =~ s/^\.\///;

is(
    $e->stack_trace->as_string,
    qq[Trace begun at $file line 22
main::bar at $file line 24
eval {...} at $file line 24
],
    '... got the exception'
);

done_testing;

