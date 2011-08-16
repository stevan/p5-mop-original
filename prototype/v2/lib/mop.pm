package mop;

use strict;
use warnings;

use Clone        ();
use Scalar::Util ();

use mop::internal::instance;
use mop::internal::dispatcher;

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
$::SELF  = undef;
$::CLASS = undef;

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

$::Class = mop::internal::instance::create(
    \$::Class,
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

$::Object = mop::internal::instance::create(
    \$::Class,
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

                bless(
                    mop::internal::instance::create(
                        \$::SELF,
                        $instance
                    ),
                    'mop::dispatchable'
                );
            },
            'id'    => sub { mop::internal::instance::get_uuid( $::SELF ) },
            'class' => sub { mop::internal::instance::get_class( $::SELF ) },
        }
    }
);

mop::internal::instance::get_data_at( $::Class, '$superclasses' )->[0] = $::Object;

bless( $::Class, 'mop::dispatchable' );
bless( $::Object, 'mop::dispatchable' );

## ------------------------------------------------------------------
## Sugar Layer
## ------------------------------------------------------------------

# this is simply here because we need to have dispatching behavior
# on our instances.

{
    # NOTE:
    # The exact implementation of this is heavily tied to the prototype
    # and making the prototype behave as expected on the user language
    # level.

    # Specifically, we are using AUTOLOAD here as a general purpose
    # dispatching mechanism. This is simply a means of making the
    # prototype work, it should not be seen as a recommendation for
    # the actual implementation.

    package mop::dispatchable;
    use strict;
    use warnings;

    sub NEXTMETHOD {
        my $invocant    = shift;
        my $method_name = shift;
        mop::internal::dispatcher::NEXTMETHOD( $method_name, $invocant, @_ );
    }

    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        mop::internal::dispatcher::DISPATCH( $method_name, @_ );
    }
}

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

    push @{ $meta->{'superclasses'} } => $::Object
        unless scalar @{ $meta->{'superclasses'} };

    $::Class->new( %$meta );
}

## ------------------------------------------------------------------
## Exporting
## ------------------------------------------------------------------

my ($self, $class);

sub import {
    my $from = shift;
    my $to   = caller;
    {
         no strict 'refs';
         *{"${to}::class"}   = \&class;
         *{"${to}::method"}  = \&method;
         *{"${to}::extends"} = \&extends;
    }
}

1;

__END__

=pod

=head1 NAME

mop

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut