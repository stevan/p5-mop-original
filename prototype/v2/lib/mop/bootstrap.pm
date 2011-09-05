package mop::bootstrap;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;
use mop::internal::attribute;
use mop::internal::method;

sub init {

    $::Class = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Class',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [],
        attributes   => {},
        methods      => {
            'get_mro'  => mop::internal::method::create(
                name => 'get_mro',
                body => sub { mop::internal::class::get_mro( $::SELF ) }
            ),
            'get_attributes' => mop::internal::method::create(
                name => 'get_attributes',
                body => sub { mop::internal::instance::get_data_at( $::SELF, '$attributes' ) }
            ),
            'find_method' => mop::internal::method::create(
                name => 'find_method',
                body => sub {
                    my $method_name = shift;
                    mop::internal::class::find_method( $::SELF, $method_name )
                }
            )
        }
    );

    bless( $::Class, 'mop::syntax::dispatchable' );

    $::Object = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Object',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [],
        attributes   => {},
        methods      => {
            'new'   => mop::internal::method::create(
                name => 'new',
                body => sub {
                    my %args = @_;

                    my $data = {};

                    foreach my $class ( @{ $::SELF->get_mro } ) {
                        my $attrs = $class->get_attributes;
                        foreach my $attr_name ( keys %$attrs ) {
                            unless ( exists $data->{ $attr_name } ) {
                                $data->{ $attr_name } = mop::internal::attribute::get_initial_value_for_instance(
                                    $attrs->{ $attr_name }
                                );
                            }
                        }
                    }

                    foreach my $arg ( keys %args ) {
                        my $value = $args{ $arg };
                        $data->{ '$' . $arg } = \$value;
                    }

                    my $self = bless(
                        mop::internal::instance::create(
                            \$::SELF,
                            $data
                        ),
                        'mop::syntax::dispatchable'
                    );

                    $self->BUILDALL( \%args );

                    return $self;
                }
            ),
            'BUILDALL' => mop::internal::method::create(
                name => 'BUILDALL',
                body => sub {
                    my $args = shift;
                    foreach my $class ( reverse @{ $::CLASS->get_mro } ) {
                        if ( my $BUILD = $class->find_method( 'BUILD' ) ) {
                            mop::internal::method::execute( $BUILD, $::SELF, $args );
                        }
                    }
                }
            ),
        },
    );

    mop::internal::instance::get_data_at( $::Class, '$superclasses' )->[0] = $::Object;

    bless( $::Object,      'mop::syntax::dispatchable' );

    $::Method = $::Class->new(
        name         => 'Method',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [ $::Object ],
        attributes   => {},
        methods      => {},
    );

    $::Attribute = $::Class->new(
        name         => 'Class',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [ $::Object ],
        attributes   => {},
        methods      => {},
    );

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