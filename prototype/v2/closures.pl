#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use PadWalker qw[ set_closed_over closed_over peek_sub peek_my ];

=pod

So this is an exploration of a more minimalist
and prototype style OO system (except without
the prototypes).

Some of the things that appeal to me are the
following:

* the class is a really just a factory for instances
* an instance is defined as the lexical environment
  of its methods
* private instance slots (mostly)

Some of the things that annoy me:

* No easy way to make inheritance work
* there is no concrete instance, only a lexical pad

=cut

my $self;

{
    # For syntactic sugar only
    package Dispatchable;
    sub AUTOLOAD {
        my @autoload = (split '::', our $AUTOLOAD);
        my $method   = $autoload[-1];
        return if $method eq 'DESTROY';

        my $invocant  = shift;
        local $::self = $invocant;
        $invocant->( $method, @_ );
    }
}

sub method {
    my ($name, $body) = @_;
    my $pad = peek_my(2);
    ${$pad->{'$vtable'}}->{ $name } = $body;
}

sub class (&) {
    my $body = shift;

    # capture the attributes
    # defined in the class
    my $attrs = peek_sub( $body );

    # capture the methods
    # defined in the class
    my $vtable = {};
    $body->();

    sub {
        my %args = @_;

        # build the instance environment
        # by using the original class
        # environment as a starting point
        my $instance = { %{$attrs} };
        foreach my $arg ( keys %args ) {
            my $value = $args{ $arg };
            $instance->{ '$' . $arg } = \$value;
        }

        bless sub {
            my ($method_name, @args) = @_;
            my $method = $vtable->{ $method_name };
            set_closed_over( $method, $instance );
            $method->( @args );
        } => 'Dispatchable';
    }
}

## ------------------------------------------------------------------
## Prototypin!
## ------------------------------------------------------------------

my $Point = class {
    my $x = 100;
    my $y;

    method 'x' => sub { $x };
    method 'y' => sub { $y };

    method 'set_x' => sub {
        my $new_x = shift;
        $x = $new_x;
    };

    method 'dump' => sub {
        +{ x => $::self->x, y => $y }
    };
};

my $p = $Point->( y => 320 );

is $p->x, 100;
is $p->y, 320;
is_deeply $p->dump, { x => 100, y => 320 };

$p->set_x(10);
is $p->x, 10;

is_deeply $p->dump, { x => 10, y => 320 };

my $p2 = $Point->( x => 1, y => 30 );

is $p2->x, 1;
is $p2->y, 30;
is_deeply $p2->dump, { x => 1, y => 30 };

$p2->set_x(500);
is $p2->x, 500;
is_deeply $p2->dump, { x => 500, y => 30 };

is $p->x, 10;
is $p->y, 320;
is_deeply $p->dump, { x => 10, y => 320 };


done_testing;

