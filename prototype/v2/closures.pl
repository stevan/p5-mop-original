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

    # to hold the metaclass
    # if we decide to make it
    my $meta;

    # capture the attributes
    # defined in the class
    my $attrs = peek_sub( $body );

    # capture the methods
    # defined in the class
    my $vtable = {};
    $body->();

    bless sub {
        my $method_name = shift;

        if ( $method_name eq 'new' ) {
            my %args = @_;
            # build the instance environment
            # by using the original class
            # environment as a starting point
            my $instance = { %{$attrs} };
            foreach my $arg ( keys %args ) {
                my $value = $args{ $arg };
                $instance->{ '$' . $arg } = \$value;
            }

            return bless sub {
                my ($method_name, @args) = @_;
                my $method = $vtable->{ $method_name };
                die "Cannot find method '$method_name'\n"
                    unless defined $method;
                set_closed_over( $method, $instance );
                $method->( @args );
            } => 'Dispatchable';
        }
        elsif ( $method_name eq 'meta' ) {

            unless ( $meta ) {
                $meta = class(sub {
                    method 'get_attributes' => sub { $attrs  };
                    method 'get_methods'    => sub { $vtable };
                    method 'add_method'     => sub {
                        my ($name, $method) = @_;
                        $vtable->{ $name } = $method;
                    };
                })->new;
            }

            return $meta;
        }
        else {
            die "Cannot find class method '$method_name'\n";
        }
    } => 'Dispatchable';
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

my $meta = $Point->meta;

is_deeply [ sort keys %{$meta->get_methods} ], [qw[ dump set_x x y ]], '... got the method list we expected';
is_deeply $meta->get_attributes, { '$x' => \100, '$y' => \undef }, '... got the attribute list we expected';

my $p = $Point->new( y => 320 );

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

# get all meta on this ...
$meta->add_method(
    'as_string' => sub {
        $::self->x . ' x ' . $::self->y
    }
);

is $p->as_string, '10 x 320', '... got the expected value from the new method';

my $p2 = $Point->new( x => 1, y => 30 );

is $p2->as_string, '1 x 30', '... got the expected value from the new method (again)';

is $p2->x, 1, '... got the right value for x';
is $p2->y, 30, '... got the right value for y';
is_deeply $p2->dump, { x => 1, y => 30 }, '... got the right value from dump';

$p2->set_x(500);
is $p2->x, 500, '... got the right value for x';
is_deeply $p2->dump, { x => 500, y => 30 }, '... got the right value from dump';

is $p->x, 10, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';


done_testing;

