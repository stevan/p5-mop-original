package mop::bootstrap;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;
use mop::internal::attribute;
use mop::internal::method;

sub init {

    ## --------------------------------
    ## Create our classes
    ## --------------------------------

    $::Class = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Class',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [],
        attributes   => {},
        methods      => {
            'add_method' => mop::internal::method::create(
                name => 'add_method',
                body => sub {
                    my $method = shift;
                    mop::internal::instance::get_slot_at( $::SELF, '$methods' )->{
                        mop::internal::instance::get_slot_at( $method, '$name' )
                    } = $method;
                }
            ),
            'CREATE'   => mop::internal::method::create(
                name => 'CREATE',
                body => sub {
                    my $args = shift;
                    my $data = {};

                    foreach my $class ( @{ mop::internal::class::get_mro( $::SELF ) } ) {
                        my $attrs = mop::internal::instance::get_slot_at( $class, '$attributes' );
                        foreach my $attr_name ( keys %$attrs ) {
                            unless ( exists $data->{ $attr_name } ) {
                                my $param_name = $attr_name;
                                $param_name =~ s/^\$//;

                                if ( exists $args->{ $param_name } ) {
                                    my $value = $args->{ $param_name };
                                    $data->{ $attr_name } = \$value;
                                }
                                else {
                                    $data->{ $attr_name } = mop::internal::attribute::get_initial_value_for_instance(
                                        $attrs->{ $attr_name }
                                    );
                                }

                            }
                        }
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
            'new'   => mop::internal::method::create(
                name => 'new',
                body => sub {
                    my %args = @_;

                    my $data = $::SELF->CREATE( \%args );

                    my $self = bless(
                        mop::internal::instance::create( \$::SELF, $data ),
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
                    foreach my $class ( reverse @{ mop::internal::class::get_mro( $::CLASS ) } ) {
                        if ( my $BUILD = mop::internal::class::find_method( $class, 'BUILD' ) ) {
                            mop::internal::method::execute( $BUILD, $::SELF, $args );
                        }
                    }
                }
            ),
        },
    );

    $::Method = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Method',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [ $::Object ],
        methods      => {},
        attributes   => {
            '$name' => mop::internal::attribute::create( name => '$name', initial_value => \(my $method_name) ),
            '$body' => mop::internal::attribute::create( name => '$body', initial_value => \(my $method_body) ),
        },
    );

    $::Attribute = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Attribute',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [ $::Object ],
        methods      => {},
        attributes   => {
            '$name'          => mop::internal::attribute::create( name => '$name',          initial_value => \(my $attribute_name) ),
            '$initial_value' => mop::internal::attribute::create( name => '$initial_value', initial_value => \(my $initial_value)  ),
        },
    );

    ## --------------------------------
    ## START BOOTSTRAP
    ## --------------------------------

    mop::internal::instance::get_slot_at( $::Class, '$superclasses' )->[0] = $::Object;

    bless( $::Object,    'mop::syntax::dispatchable' );
    bless( $::Class,     'mop::syntax::dispatchable' );
    bless( $::Method,    'mop::syntax::dispatchable' );
    bless( $::Attribute, 'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'add_method'}, 'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'CREATE'},     'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Object, '$methods' )->{'new'},      'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Object, '$methods' )->{'BUILDALL'}, 'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Method, '$attributes' )->{'$name'}, 'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Method, '$attributes' )->{'$body'}, 'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$name'},          'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$initial_value'}, 'mop::syntax::dispatchable' );

    ## --------------------------------
    ## $::Class
    ## --------------------------------

    ## accessors

    $::Class->add_method( $::Method->new( name => 'get_name',         body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' )         } ) );
    $::Class->add_method( $::Method->new( name => 'get_version',      body => sub { mop::internal::instance::get_slot_at( $::SELF, '$version' )      } ) );
    $::Class->add_method( $::Method->new( name => 'get_authority',    body => sub { mop::internal::instance::get_slot_at( $::SELF, '$authority' )    } ) );
    $::Class->add_method( $::Method->new( name => 'get_superclasses', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$superclasses' ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_methods',      body => sub { mop::internal::instance::get_slot_at( $::SELF, '$methods' )      } ) );
    $::Class->add_method( $::Method->new( name => 'get_attributes',   body => sub { mop::internal::instance::get_slot_at( $::SELF, '$attributes' )   } ) );
    $::Class->add_method( $::Method->new( name => 'get_mro',          body => sub { mop::internal::class::get_mro( $::SELF ) } ) );
    $::Class->add_method( $::Method->new( name => 'attribute_class',  body => sub { $::Attribute } ) );
    $::Class->add_method( $::Method->new( name => 'method_class',     body => sub { $::Method } ) );
    $::Class->add_method( $::Method->new( name => 'find_method', body => sub {
        my $method_name = shift;
        mop::internal::class::find_method( $::SELF, $method_name )
    }));

    ## mutators

    $::Class->add_method( $::Method->new( name => 'add_superclass', body => sub {
        my $superclass = shift;
        push @{ $::SELF->get_superclasses } => $superclass;
    }));
    $::Class->add_method( $::Method->new( name => 'add_attribute', body => sub {
        my $attr = shift;
        $::SELF->get_attributes->{ mop::internal::instance::get_slot_at( $attr, '$name' ) } = $attr;
    }));

    ## predicate methods ...

    $::Class->add_method( $::Method->new( name => 'is_subclass_of', body => sub {
        my $super = shift;
        my @mro   = @{ $::SELF->get_mro };
        shift @mro;
        scalar grep { $super->id eq $_->id } @mro;
    }));

    ## class protocol

    $::Class->add_method( $::Method->new( name => 'FINALIZE', body => sub {
        $::SELF->add_superclass( $::Object )
            unless scalar @{ $::SELF->get_superclasses };
    }));

    ## add in the attributes

    $::Class->add_attribute( $::Attribute->new( name => '$name',         initial_value => \(my $class_name) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$version',      initial_value => \(my $class_version) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$authority',    initial_value => \(my $class_authority) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$superclasses', initial_value => \([]) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$attributes',   initial_value => \({}) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$methods',      initial_value => \({}) ) );

    ## --------------------------------
    ## $::Object
    ## --------------------------------

    $::Object->add_method( $::Method->new( name => 'id',    body => sub { mop::internal::instance::get_uuid( $::SELF )  } ) );
    $::Object->add_method( $::Method->new( name => 'class', body => sub { mop::internal::instance::get_class( $::SELF ) } ) );
    $::Object->add_method( $::Method->new( name => 'is_a',  body => sub { $::CLASS->id eq $_[0]->id || $::CLASS->is_subclass_of( $_[0] ) } ) );

    ## --------------------------------
    ## $::Method
    ## --------------------------------

    $::Method->add_method( $::Method->new( name => 'get_name', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' ) } ) );
    $::Method->add_method( $::Method->new( name => 'get_body', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$body' ) } ) );

    ## --------------------------------
    ## $::Attribute
    ## --------------------------------

    $::Attribute->add_method( $::Method->new( name => 'get_name',          body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' ) } ) );
    $::Attribute->add_method( $::Method->new( name => 'get_initial_value', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$initial_value' ) } ) );
    $::Attribute->add_method( $::Method->new( name => 'get_initial_value_for_instance', body => sub {
        mop::internal::attribute::get_initial_value_for_instance( $::SELF )
    }));

    ## --------------------------------
    ## END BOOTSTRAP
    ## --------------------------------

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