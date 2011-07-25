#!perl

use strict;
use warnings;

use PadWalker    ();
use Clone        ();
use Scalar::Util ();

use Test::More;

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
## Low-Level Instance Structure
## ------------------------------------------------------------------

# This is the low-level instance data structure, it should not be
# confused with the Instance Meta Protocol, which will be defined
# later on.

# There are basically three fields in an instance structure.

# The first is a unique identifier. I am using Data::UUID here so that
# we can be sure the value will be unique accross processes, threads
# and machines. I think this is important for any modern object system
# that is to be built within a networked world.

# The second is a reference to the Class object that this instance
# is connected too.

# The third is the structure to hold the actual instance data itself.
# This is a HASH ref in which all the keys are references as well. This
# data structure is compatible with what PadWalker::set_closed_over
# expects for arguments. The reason being that in every method call
# we use this data structure as the lexical pad for that method. This
# will be explained more further down.

# It should also be noted that we bless our instances into the
# 'mop::dispatchable' package, which is done mostly to make the
# prototype function correctly, although the 'mop::dispatchable'
# does have use beyond just the prototype (see below).

# TODO:
# I think that get_data_at needs some re-thinking to improve how
# we handle missing data, perhaps an exception.

{
    package mop::instance;
    use strict;
    use warnings;
    use Data::UUID;

    my $UUID = Data::UUID->new;

    sub create {
        my ($class, $data) = @_;
        bless {
            uuid  => $UUID->create_str,
            class => $class,
            data  => $data
        } => 'mop::dispatchable';
    }

    sub get_uuid  { (shift)->{'uuid'}     }
    sub get_class { ${(shift)->{'class'}} }
    sub get_data  { (shift)->{'data'}     }
    sub get_data_at {
        my ($instance, $name) = @_;
        ${ $instance->{'data'}->{ $name } || \undef }
    }
}

## ------------------------------------------------------------------
## Low-Level Dispatcher
## ------------------------------------------------------------------

# The exact implementation of this is heavily tied to the prototype
# and making the prototype behave as expected on the user language
# level. However, that is not all that it does.

# The real useful parts of the dispatcher are the three methods;
# WALKMETH, WALKCLASS and DISPATCH. These were somewhat borrowed
# from Perl 6, but with some modifications. Each one has a specific
# set of responsibilities.

# WALKMETH is primarliy responsible for finding a method within a
# given class. This means that it must know enough about a Class
# object to be able to find a method within it.

# WALKCLASS is primarily responsible for traversing the MRO of
# a Class object and applying a $solver callback to each class
# until the callback returns something.

# DISPATCH is concerned with setting up a method to be executed.
# This means finding the method, setting up the lexical environment
# for the method and finally executing the method.

# Finally, we are using AUTOLOAD here as a general purpose
# dispatching mechanism. This is simply a means of making the
# prototype work, it should not be seen as a recommendation for
# the actual implementation.

# TODO:
# We should add some kind of NEXT::METHOD implementation here
# as well that can handle proper SUPER style dispatching.

{
    package mop::dispatchable;
    use strict;
    use warnings;
    use PadWalker ();

    sub WALKMETH {
        my ($class, $method_name) = @_;
        WALKCLASS( $class, sub { mop::instance::get_data_at( $_[0], '$methods' )->{ $method_name } } );
    }

    sub WALKCLASS {
        my ($class, $solver) = @_;
        if ( my $result = $solver->( $class ) ) {
            return $result;
        }
        foreach my $super ( @{ mop::instance::get_data_at( $class, '$superclasses' ) } ) {
            if ( my $result = WALKCLASS( $super, $solver ) ) {
                return $result;
            }
        }
    }

    sub DISPATCH {
        my $method_name = shift;
        my $invocant    = shift;
        my $class       = mop::instance::get_class( $invocant );
        my $method      = WALKMETH( $class, $method_name ) || die "Could not find method '$method_name'";
        my $instance    = mop::instance::get_data( $invocant );

        PadWalker::set_closed_over( $method, {
            %$instance,
            '$self'  => \$invocant,
            '$class' => \$class
        });

        local $::SELF  = $invocant;
        local $::CLASS = $class;

        $method->( @_ );
    }

    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        DISPATCH( $method_name, @_ );
    }
}

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

$Class = mop::instance::create(
    \$Class,
    {
        '$superclasses' => \[],
        '$attributes'   => \{},
        '$methods'      => \{
            'get_superclasses' => sub { mop::instance::get_data_at( $::SELF, '$superclasses' ) },
            'get_methods'      => sub { mop::instance::get_data_at( $::SELF, '$methods' )      },
            'get_attributes'   => sub { mop::instance::get_data_at( $::SELF, '$attributes' )   },
            'get_mro'          => sub {
                return [
                    $::SELF,
                    map { @{ $_->get_mro } } @{ $::SELF->get_superclasses }
                ]
            }
        }
    }
);

my $Object = mop::instance::create(
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

                return mop::instance::create(
                    \$::SELF,
                    $instance
                );
            },
            'id'    => sub { mop::instance::get_uuid( $::SELF ) },
            'class' => sub { mop::instance::get_class( $::SELF ) },
        }
    }
);

mop::instance::get_data_at( $Class, '$superclasses' )->[0] = $Object;

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
};

my $p3d = $Point3D->new( x => 1, y => 2, z => 3 );

is $p3d->x, 1, '... got the right value for x';
is $p3d->y, 2, '... got the right value for y';
is $p3d->z, 3, '... got the right value for z';

done_testing;



















