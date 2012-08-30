#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Requires 'Devel::StackTrace';

use mop;

use lib 't/400-yapc-eu-examples/lib/';

use Throwable;

class MyError ( with => [Throwable] ) {}

my $line = __LINE__;
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

my $line1 = $line + 2;
my $line2 = $line + 4;
my $line3 = $line + 4;
is(
    $e->stack_trace->as_string,
    qq[Trace begun at $file line $line1
main::bar at $file line $line2
eval {...} at $file line $line3
],
    '... got the exception'
);

done_testing;

