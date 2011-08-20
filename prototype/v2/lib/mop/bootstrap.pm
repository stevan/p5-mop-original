package mop::bootstrap;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;

use Clone ();

sub init {

    $::Class = mop::internal::class::create(
        methods => {
            'get_superclasses' => sub { mop::internal::class::get_superclasses( $::SELF ) },
            'get_methods'      => sub { mop::internal::class::get_methods( $::SELF )      },
            'get_attributes'   => sub { mop::internal::class::get_attributes( $::SELF )   },
            'get_mro'          => sub { mop::internal::class::get_mro( $::SELF )          },
        }
    );

    $::Object = mop::internal::class::create(
        methods => {
            'id'    => sub { mop::internal::instance::get_uuid( $::SELF ) },
            'class' => sub { mop::internal::instance::get_class( $::SELF ) },
            'new'   => sub {
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
                    'mop::syntax::dispatchable'
                );
            }
        }
    );

    mop::internal::class::get_superclasses( $::Class )->[0] = $::Object;

    bless( $::Class, 'mop::syntax::dispatchable' );
    bless( $::Object, 'mop::syntax::dispatchable' );

    return;
}

1;

__END__

=pod

=head1 NAME

mop::internal::boostrap

=head1 DESCRIPTION

The boostratpping process is important, but a little ugly and
manual. The main goal of the bootstrap is to define the class Class
as well as the class Object, and to "tie the knot" such that the
following things are true:

  - Class is an instance of Class
  - Object is an instance of Class
  - Class is a subclass of Object

This is what will give us our desired "turtles all the way down"
metacircularity.

-head1 TODO

These definitions should actually get stripped down to their bare
minimums so that there is less to overwrite in the MOP boostrap
that we do later on.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut