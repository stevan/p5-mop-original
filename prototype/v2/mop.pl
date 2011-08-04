#!perl

use strict;
use warnings;

use Clone        ();
use Scalar::Util ();
use Test::More;

use mop;

## ------------------------------------------------------------------
## Global Variable setup
## ------------------------------------------------------------------

# These are global variables of the current invocant
# and current class of the invocant, they are localized
# within the body of the current method being executed.
# These are needed mostly in the bootstrap process so
# that the class Class and class Object can have access
# to them. I suspect that a similar concept may be
# required in the implemntation of the MOP, though it
# might not need to be accessible at the language level.
our ($SELF, $CLASS);

# These are the same as above, in that they are the
# current invocant and current class of the invocant.
# These must be defined globally so that both $self
# and $class will be valid within the bodies of methods
# in a class definition. So, in a sense, this is just
# part of the syntactic sugar layer needed by this
# prototype and should not reflect how this should
# be implemented within the interpreter.
my ($self, $class);

## ------------------------------------------------------------------
## Boostrapping
## ------------------------------------------------------------------

# The boostratpping process is important, but a little ugly and
# manual. The main goal of the bootstrap is to define the class Class
# as well as the class Object, and to "tie the knot" such that the
# following things are true:
#
# - Class is an instance of Class
# - Object is an instance of Class
# - Class is a subclass of Object
#
# This is what will give us our desired "turtles all the way down"
# metacircularity.

# TODO:
# These definitions should actually get stripped down to their bare
# minimums so that there is less to overwrite in the MOP boostrap
# that we do later on.

my $Class;

$Class = mop::internal::instance::create(
    \$Class,
    {
        '$superclasses' => \[],
        '$attributes'   => \{},
        '$methods'      => \{
            'get_superclasses' => sub { mop::internal::instance::get_data_at( $::SELF, '$superclasses' ) },
            'get_methods'      => sub { mop::internal::instance::get_data_at( $::SELF, '$methods' )      },
            'get_attributes'   => sub { mop::internal::instance::get_data_at( $::SELF, '$attributes' )   },
            'get_mro'          => sub {
                return [
                    $::SELF,
                    map { @{ $_->get_mro } } @{ $::SELF->get_superclasses }
                ]
            }
        }
    }
);

my $Object = mop::internal::instance::create(
    \$Class,
    {
        '$superclasses' => \[],
        '$attributes'   => \{},
        '$methods'      => \{
            'new' => sub {
                my %args  = @_;

                my $instance = {};

                foreach my $class ( @{ $::SELF->get_mro } ) {
                    my $attrs = $class->get_attributes;
                    foreach my $attr_name ( keys %$attrs ) {
                        unless ( exists $instance->{ $attr_name } ) {
                            my $value = ${ $attrs->{ $attr_name } };
                            $value = Clone::clone( $value ) if ref $value;
                            $instance->{ $attr_name } = \$value;
                        }
                    }
                }

                foreach my $arg ( keys %args ) {
                    my $value = $args{ $arg };
                    $instance->{ '$' . $arg } = \$value;
                }

                return mop::internal::instance::create(
                    \$::SELF,
                    $instance
                );
            },
            'id'    => sub { mop::internal::instance::get_uuid( $::SELF ) },
            'class' => sub { mop::internal::instance::get_class( $::SELF ) },
        }
    }
);

mop::internal::instance::get_data_at( $Class, '$superclasses' )->[0] = $Object;

## ------------------------------------------------------------------
## Sugar Layer
## ------------------------------------------------------------------

# The primary responsibility of these next 3 functions is to provide
# a sugar layer for the creation of classes. Exactly how this would
# work in a real implementation is unknown, but this does the job
# (in a kind of scary PadWalker-ish way) for now.

# TODO:
# improve the handling and detection of attributes, right now it
# is too much guessing.

sub method {
    my ($name, $body) = @_;
    my $pad = PadWalker::peek_my(2);
    ${$pad->{'$meta'}}->{'methods'}->{ $name } = $body;
}

sub extends {
    my ($superclass) = @_;
    my $pad = PadWalker::peek_my(2);
    push @{ ${$pad->{'$meta'}}->{'superclasses'} } => $superclass;
}

sub class (&) {
    my $body = shift;

    my $meta = {
        'methods'      => {},
        'superclasses' => [],
    };

    my $attrs = PadWalker::peek_sub( $body );

    # NOTE:
    # we need to use some guessing here to
    # make sure we are only capturing the
    # variable actually intended as attributes
    # and not other lexicals PadWalker might
    # see. So the first thing we do is get
    # rid of $self and $class, which we know
    # are not acceptable.

    delete $attrs->{'$self'};
    delete $attrs->{'$class'};

    # The next thing we do is to remove any
    # closed over classes, such as would occur
    # with the 'extends' statement.

    foreach my $attr ( keys %$attrs ) {
        delete $attrs->{ $attr }
            if Scalar::Util::blessed ${ $attrs->{ $attr } };
    }

    # none of the above technique for
    # cleaning the attrs HASH are ideal
    # but this is just a hacked up sugar
    # layer, so we live with it for the
    # protototype.

    $meta->{'attributes'} = $attrs;

    $body->();

    push @{ $meta->{'superclasses'} } => $Object
        unless scalar @{ $meta->{'superclasses'} };

    $Class->new( %$meta );
}

## ------------------------------------------------------------------
## MOP
## ------------------------------------------------------------------

# TODO:
# In this stage, we will create the MOP objects for the following
# protocols:
#
# - Instance Protocol
# This will be primarily a wrapper around the Low-Level instance
# structure's API to give access to the guts of an instance.
#
# - Class Protocol
# This is actually started in the $Class above, but should be
# expanded here.
#
# - Method Protocol
# This will wrap each method and quite possibly we will move
# the method environment setup code from mop::dispatchable::DISPATCH
# to here, though I am not 100% sure of that.
#
# - Attribute Protocol
# This will wrap each attribute and mostly (for now) just provide
# metadata and a means of access.
#
# It is most likely (though I won't know until I do it) that we will
# put some kind of code here to re-work $Class and $Object defined
# above such that they are using the MOP themselves.

## -------------------------------------------------------------------
## Testing the whole thing ...
## -------------------------------------------------------------------

# So the class created below is still kind of rough, obviously
# the syntax needs more work. Some key things that I do like are:
#
# - access to instance data is done via lexically accessible values
# - $self and $class are valid within methods
# - the invocant is no longer in the @_
# - the class ($Point) is a concrete thing, not just a string
#
# Some of the things I would like to fix are:
#
# - using 'my' for attributes is bad, that should be 'has'
#   instead to better differentiate between attributes and
#   simple lexical variables
# - there is no good way to do class methods (yet)
# - we need to support the 'class Point { ... }' syntax
# - we do not yet have a means of capturing metadata for
#   classes, attributes and methods
#
# Otherwise, I think this is progressing along.

my $Point = class {
    my $x;
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

like $Point->id, qr/[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}/, '... got the expected uuid format';
is $Point->class, $Class, '... got the class we expected';
is_deeply $Point->get_superclasses, [ $Object ], '... got the superclasses we expected';

## Test an instance

my $p = $Point->new( x => 100, y => 320 );

like $p->id, qr/[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}/, '... got the expected uuid format';
is $p->class, $Point, '... got the class we expected';

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

my $p2 = $Point->new( x => 1, y => 30 );

isnt $p->id, $p2->id, '... not the same instances';

is $p2->x, 1, '... got the right value for x';
is $p2->y, 30, '... got the right value for y';
is_deeply $p2->dump, { x => 1, y => 30 }, '... got the right value from dump';

$p2->set_x(500);
is $p2->x, 500, '... got the right value for x';
is_deeply $p2->dump, { x => 500, y => 30 }, '... got the right value from dump';

is $p->x, 10, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

## Test a subclass

my $Point3D = class {
    extends $Point;

    my $z;

    method 'z' => sub { $z };

    method 'dump' => sub {
        my $orig = $self->NEXTMETHOD('dump');
        $orig->{'z'} = $z;
        $orig;
    };
};

my $p3d = $Point3D->new( x => 1, y => 2, z => 3 );

is $p3d->x, 1, '... got the right value for x';
is $p3d->y, 2, '... got the right value for y';
is $p3d->z, 3, '... got the right value for z';

is_deeply $p3d->dump, { x => 1, y => 2, z => 3 }, '... go the right value from dump';

done_testing;



















