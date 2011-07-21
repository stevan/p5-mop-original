#!/usr/bin/perl

use strict;
use warnings;
no warnings 'once';

use Test::More;

use Clone ();
use PadWalker qw[ set_closed_over closed_over peek_sub peek_my ];

=pod

So this is an exploration of a very minimalist OO system with a
custom instance type based on lexical pads.

Some of the things that appeal to me are the
following:

* the class is a really just a factory for instances (as it should be)
* an instance is defined by the lexical environment of its methods
* private instance slots (mostly)
* on demand metaclasses

=cut

## ------------------------------------------------------------------
## Global Variables
## ------------------------------------------------------------------

my ($self, $class);   # the current instance and class for methods
my $Meta;             # the base metaclass class

## ------------------------------------------------------------------
## Dispatching mechanism
## ------------------------------------------------------------------

{
    package Dispatchable;
    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        my $invocant = shift;
        $invocant->( $method_name, $invocant, @_ );
    }
}

## ------------------------------------------------------------------
## Internal mechanisms
## ------------------------------------------------------------------

sub FIND_METHOD {
    my ($method_name, $methods, $superclasses) = @_;

    return $methods->{ $method_name }
        if exists $methods->{ $method_name };

    foreach my $super ( @$superclasses ) {
        my $meta   = $super->meta;
        my $method = FIND_METHOD(
            $method_name,
            $meta->get_methods,
            $meta->get_superclasses
        );
        return $method if $method;
    }

    return;
}

my ($SELF, $CLASS, $INSTANCE);

sub CALL_METHOD {
    my ($method, $invocant, $class_invocant, $instance, @args) = @_;

    set_closed_over( $method, {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class_invocant,
    });

    local $::SELF     = $invocant;
    local $::CLASS    = $class_invocant;
    local $::INSTANCE = $instance;

    $method->( @args );
}

sub SUPER {
    my ($method_name, @args) = @_;
    my $method = FIND_METHOD( $method_name, {}, $::CLASS->meta->get_superclasses );
    die "No SUPER method '$method_name' found" unless defined $method;
    CALL_METHOD( $method, $::SELF, $::CLASS, $::INSTANCE, @args );
}

## ------------------------------------------------------------------
## Syntactic Sugar
## ------------------------------------------------------------------

sub method {
    my ($name, $body) = @_;
    my $pad = peek_my(2);
    ${ $pad->{'$vtable'} }->{ $name } = $body;
}

sub extends {
    my ($superclass) = @_;
    my $pad = peek_my(2);
    push @{ ${ $pad->{'$supers'} } } => $superclass;
}

## This is where most of the work is done
sub class (&) {
    my $body = shift;

    # to hold the metaclass
    # if we decide to make it
    my $meta;

    # capture the attributes
    # defined in the class
    my $attrs = peek_sub( $body );

    # this can show up accidently
    # so we just get rid of it here
    delete $attrs->{'$self'};
    delete $attrs->{'$class'};

    # capture the methods
    # defined in the class
    my $vtable = {};
    my $supers = [];
    $body->();

    bless sub {
        my $method_name    = shift;
        my $class_invocant = shift;

        if ( $method_name eq 'new' ) {
            my %args = @_;
            # build the instance environment
            # by using the original class
            # environment as a starting point
            my $instance = {};

            # first we need to clone the
            # attributes into our instance
            foreach my $attr ( keys %$attrs ) {
                my $value = ${ $attrs->{ $attr } };
                $value = Clone::clone( $value ) if ref $value;
                $instance->{ $attr } = \$value;
            }

            # then we need to clone the
            # attributes of our superclasses
            # into our instance
            foreach my $super ( @$supers) {
                my $attrs = $super->meta->get_attributes;
                foreach my $attr ( keys %$attrs ) {
                    my $value = ${ $attrs->{ $attr } };
                    $value = Clone::clone( $value ) if ref $value;
                    $instance->{ $attr } = \$value;
                }
            }

            # then we overwrite with
            # any args, making sure
            # that the args are valid
            foreach my $arg ( keys %args ) {
                die "Bad attribute '$arg'"
                    unless exists $instance->{ '$' . $arg };
                my $value = $args{ $arg };
                $instance->{ '$' . $arg } = \$value;
            }

            # now create our instance ...
            return bless sub {
                my ($method_name, $invocant, @args) = @_;
                my $method = FIND_METHOD( $method_name, $vtable, $supers );
                die "No method '$method_name' found" unless defined $method;
                CALL_METHOD( $method, $invocant, $class_invocant, $instance, @args );
            } => 'Dispatchable';
        }
        elsif ( $method_name eq 'meta' ) {
            $meta = $Meta->new(
                superclasses => $supers,
                attributes   => $attrs,
                methods      => $vtable
            ) unless $meta;
            return $meta;
        }
        else {
            die "Cannot find class method '$method_name'\n";
        }
    } => 'Dispatchable';
}

## ------------------------------------------------------------------
## Bootstrap our object system environment
## ------------------------------------------------------------------

$Meta = class {
    my $superclasses;
    my $attributes;
    my $methods;

    method 'get_superclasses' => sub { $superclasses };
    method 'get_attributes'   => sub { $attributes };
    method 'get_methods'      => sub { $methods };
    method 'find_next_method' => sub { FIND_METHOD( $_[0], {}, $superclasses ) };
    method 'add_method'       => sub {
        my ($name, $method) = @_;
        $methods->{ $name } = $method;
    };
};

## ------------------------------------------------------------------
## Try it all out
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
        +{ x => $self->x, y => $self->y }
    };
};

## Test the class

my $p = $Point->new( y => 320 );

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

## get all meta on this ...

my $meta = $Point->meta;

is_deeply [ sort keys %{$meta->get_methods} ], [qw[ dump set_x x y ]], '... got the method list we expected';
is_deeply $meta->get_attributes, { '$x' => \100, '$y' => \undef }, '... got the attribute list we expected';

# add a method ...
$meta->add_method( 'as_string' => sub { $self->x . ' x ' . $self->y } );

# check it ...
is_deeply [ sort keys %{$meta->get_methods} ], [qw[ as_string dump set_x x y ]], '... got the (updated) method list we expected';

## back to normal testing ...

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

## do some deeper meta-fiddling again

${$meta->get_attributes->{'$x'}}++;

my $p3 = $Point->new;
is $p3->x, 101, '... got the right value for x';

## Test a subclass

my $Point3D = class {
    extends $Point;

    my $z;

    method 'z'         => sub { $z };
    method 'as_string' => sub {
        return SUPER('as_string') . ' x ' . $self->z;
    };
};

my $p3d = $Point3D->new( x => 1, y => 2, z => 3 );

is $p3d->x, 1, '... got the right value for x';
is $p3d->y, 2, '... got the right value for y';
is $p3d->z, 3, '... got the right value for z';

is $p3d->as_string, '1 x 2 x 3', '... got the right value (with SUPER method)';

{
    # just checkin ...
    my $p3d = $Point3D->new;
    is $p3d->x, 101, '... got the right value for x';
}

done_testing;

