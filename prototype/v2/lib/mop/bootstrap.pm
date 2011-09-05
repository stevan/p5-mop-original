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
        attributes   => {
            '$name'         => mop::internal::attribute::create( name => '$name',         initial_value => \(my $class_name) ),
            '$version'      => mop::internal::attribute::create( name => '$version',      initial_value => \(my $class_version) ),
            '$authority'    => mop::internal::attribute::create( name => '$authority',    initial_value => \(my $class_authority) ),
            '$superclasses' => mop::internal::attribute::create( name => '$superclasses', initial_value => \([]) ),
            '$attributes'   => mop::internal::attribute::create( name => '$attributes',   initial_value => \({}) ),
            '$methods'      => mop::internal::attribute::create( name => '$methods',      initial_value => \({}) ),
        },
        methods      => {
            'get_name'         => mop::internal::method::create( name => 'get_name',         body => sub { mop::internal::instance::get_data_at( $::SELF, '$name' )         } ),
            'get_version'      => mop::internal::method::create( name => 'get_version',      body => sub { mop::internal::instance::get_data_at( $::SELF, '$version' )      } ),
            'get_authority'    => mop::internal::method::create( name => 'get_authority',    body => sub { mop::internal::instance::get_data_at( $::SELF, '$authority' )    } ),
            'get_superclasses' => mop::internal::method::create( name => 'get_superclasses', body => sub { mop::internal::instance::get_data_at( $::SELF, '$superclasses' ) } ),
            'get_methods'      => mop::internal::method::create( name => 'get_methods',      body => sub { mop::internal::instance::get_data_at( $::SELF, '$methods' )      } ),
            'get_attributes'   => mop::internal::method::create( name => 'get_attributes',   body => sub { mop::internal::instance::get_data_at( $::SELF, '$attributes' )   } ),
            'get_mro'          => mop::internal::method::create( name => 'get_mro',          body => sub { mop::internal::class::get_mro( $::SELF )                         } ),
            'find_method'      => mop::internal::method::create(
                name => 'find_method',
                body => sub {
                    my $method_name = shift;
                    mop::internal::class::find_method( $::SELF, $method_name )
                }
            ),
            # ... methods to build the class
            'add_superclass' => mop::internal::method::create( name => 'add_superclass', body => sub {
                my $superclass = shift;
                push @{ $::SELF->get_superclasses } => $superclass;
            }),
            'add_method' => mop::internal::method::create( name => 'add_method', body => sub {
                my $method = shift;
                $::SELF->get_methods->{ $method->get_name } = $method;
            }),
            'add_attribute' => mop::internal::method::create( name => 'add_attribute', body => sub {
                my $attr = shift;
                $::SELF->get_attributes->{ $attr->get_name } = $attr;
            }),
            # ... predicate methods
            'is_subclass_of' => mop::internal::method::create( name => 'is_subclass_of', body => sub {
                my $super = shift;
                my @mro   = @{ $::SELF->get_mro };
                shift @mro;
                scalar grep { $super->id eq $_->id } @mro;
            }),
            # ... class API
            'FINALIZE' => mop::internal::method::create( name => 'FINALIZE', body => sub {
                $::SELF->add_superclass( $::Object )
                    unless scalar @{ $::SELF->get_superclasses };
            }),
            # instance data creation
            'CREATE'   => mop::internal::method::create(
                name => 'CREATE',
                body => sub {
                    my $args = shift;
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

                    foreach my $arg ( keys %$args ) {
                        my $value = $args->{ $arg };
                        $data->{ '$' . $arg } = \$value;
                    }

                    return $data;
                }
            )
        }
    );

    $::Object = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Object',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [],
        attributes   => {},
        methods      => {
            'id'    => mop::internal::method::create( name => 'id',    body => sub { mop::internal::instance::get_uuid( $::SELF )  } ),
            'class' => mop::internal::method::create( name => 'class', body => sub { mop::internal::instance::get_class( $::SELF ) } ),
            'is_a'  => mop::internal::method::create( name => 'is_a',  body => sub { $::CLASS->id eq $_[0]->id || $::CLASS->is_subclass_of( $_[0] ) } ),
            'new'   => mop::internal::method::create(
                name => 'new',
                body => sub {
                    my %args = @_;

                    my $data = $::CLASS->CREATE( \%args );

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

    bless( $::Object, 'mop::syntax::dispatchable' );
    bless( $::Class,  'mop::syntax::dispatchable' );

    $::Method = $::Class->new(
        name         => 'Method',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [ $::Object ],
        attributes   => {
            '$name' => mop::internal::attribute::create( name => '$name', initial_value => \(my $method_name) ),
            '$body' => mop::internal::attribute::create( name => '$body', initial_value => \(my $method_body) ),
        },
        methods      => {
            'get_name' => mop::internal::method::create( name => 'get_name', body => sub { mop::internal::instance::get_data_at( $::SELF, '$name' ) } ),
            'get_body' => mop::internal::method::create( name => 'get_name', body => sub { mop::internal::instance::get_data_at( $::SELF, '$body' ) } ),
        },
    );

    $::Attribute = $::Class->new(
        name         => 'Class',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [ $::Object ],
        attributes   => {
            '$name'          => mop::internal::attribute::create( name => '$name',          initial_value => \(my $attribute_name) ),
            '$initial_value' => mop::internal::attribute::create( name => '$initial_value', initial_value => \(my $initial_value) ),
        },
        methods      => {
            'get_name'          => $::Method->new( name => 'get_name', body => sub { mop::internal::instance::get_data_at( $::SELF, '$name' ) } ),
            'get_initial_value' => $::Method->new( name => 'get_name', body => sub { mop::internal::instance::get_data_at( $::SELF, '$initial_value' ) } ),
        },
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