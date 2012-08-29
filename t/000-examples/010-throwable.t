#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Devel::StackTrace; 1 }
    or plan skip_all => "Devel::StackTrace is required for this test";
}

use mop;

role Throwable {

    has $message     = '';
    has $stack_trace = Devel::StackTrace->new(
        frame_filter => sub {
            $_[0]->{'caller'}->[3] !~ /^mop\:\:/ &&
            $_[0]->{'caller'}->[0] !~ /^mop\:\:/
        }
    );

    method message     { $message     }
    method stack_trace { $stack_trace }
    method throw       { die $self    }
    method as_string   { $message . "\n\n" . $stack_trace->as_string }
}

class MyError ( with => [Throwable] ) {}

sub foo { MyError->new( message => "HELLO" )->throw }
sub bar { foo() }

eval { bar };
my $e = $@;

ok( $e->isa( MyError ), '... the exception is a Throwable object' );
ok( $e->does( Throwable ), '... the exception does the Throwable role' );

is( $e->message, 'HELLO', '... got the exception' );

isa_ok( $e->stack_trace, 'Devel::StackTrace' );

my $file = __FILE__;
$file =~ s/^\.\///;

is(
    $e->stack_trace->as_string,
    qq[Trace begun at $file line 34
main::bar at $file line 36
eval {...} at $file line 36
],
    '... got the exception'
);

done_testing;

