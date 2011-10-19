package mop::bootstrap;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::role;
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
        roles        => [],
        attributes   => {},
        methods      => {
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

                    bless(
                        mop::internal::instance::create( \$::SELF, $data ),
                        'mop::syntax::dispatchable'
                    );
                }
            )
        }
    );

    $::Role = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Role',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [],
        roles        => [],
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
            'add_attribute' => mop::internal::method::create(
                name => 'add_attribute',
                body => sub {
                    my $attr = shift;
                    mop::internal::instance::get_slot_at( $::SELF, '$attributes' )->{
                        mop::internal::instance::get_slot_at( $attr, '$name' )
                    } = $attr;
                },
            ),
            'apply' => mop::internal::method::create(
                name => 'apply',
                body => sub {
                    my @roles = shift;
                    mop::internal::role::apply( $::SELF, @roles );
                    push @{ mop::internal::instance::get_slot_at( $::SELF, '$roles' ) }, @roles;
                },
            ),
        },
    );

    $::Object = mop::internal::class::create(
        class        => \$::Class,
        name         => 'Object',
        version      => '0.01',
        authority    => 'cpan:STEVAN',
        superclasses => [],
        roles        => [],
        attributes   => {},
        methods      => {
            'new'   => mop::internal::method::create(
                name => 'new',
                body => sub {
                    my %args = @_;
                    my $self = $::SELF->CREATE( \%args );
                    mop::internal::dispatcher::SUBDISPATCH(
                        sub { mop::internal::class::get_constructor( $_[0] ) },
                        1,
                        $self,
                        \%args,
                    );
                    $self;
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
        roles        => [],
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
        roles        => [],
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
    mop::internal::instance::get_slot_at( $::Role, '$superclasses' )->[0] = $::Object;
    mop::internal::role::apply( $::Class, $::Role );
    mop::internal::instance::get_slot_at( $::Class, '$roles' )->[0] = $::Role;
    mop::internal::instance::get_slot_at( $::Role, '$roles' )->[0] = $::Role;

    bless( $::Object,    'mop::syntax::dispatchable' );
    bless( $::Class,     'mop::syntax::dispatchable' );
    bless( $::Role,      'mop::syntax::dispatchable' );
    bless( $::Method,    'mop::syntax::dispatchable' );
    bless( $::Attribute, 'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Role, '$methods' )->{'add_method'}, 'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Role, '$methods' )->{'add_attribute'}, 'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Role, '$methods' )->{'apply'}, 'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'CREATE'},     'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Object, '$methods' )->{'new'},      'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Method, '$attributes' )->{'$name'}, 'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Method, '$attributes' )->{'$body'}, 'mop::syntax::dispatchable' );

    bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$name'},          'mop::syntax::dispatchable' );
    bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$initial_value'}, 'mop::syntax::dispatchable' );

    ## --------------------------------
    ## $::Class
    ## --------------------------------

    ## accessors

    $::Role->add_method( $::Method->new( name => 'does_role', body => sub { mop::internal::role::does( $::SELF, $_[0] ) } ) );
    $::Role->add_method( $::Method->new( name => 'get_name',         body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' )         } ) );
    $::Role->add_method( $::Method->new( name => 'get_version',      body => sub { mop::internal::instance::get_slot_at( $::SELF, '$version' )      } ) );
    $::Role->add_method( $::Method->new( name => 'get_authority',    body => sub { mop::internal::instance::get_slot_at( $::SELF, '$authority' )    } ) );
    $::Role->add_method( $::Method->new( name => 'get_methods',      body => sub { mop::internal::instance::get_slot_at( $::SELF, '$methods' )      } ) );
    $::Role->add_method( $::Method->new( name => 'get_attributes',   body => sub { mop::internal::instance::get_slot_at( $::SELF, '$attributes' )   } ) );
    $::Role->add_method( $::Method->new( name => 'attribute_class',  body => sub { $::Attribute } ) );
    $::Role->add_method( $::Method->new( name => 'method_class',     body => sub { $::Method } ) );
    $::Role->add_method( $::Method->new( name => 'find_method', body => sub {
        my $method_name = shift;
        mop::internal::class::find_method( $::SELF, $method_name )
    }));

    $::Class->add_method( $::Method->new( name => 'get_superclasses', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$superclasses' ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_destructor',   body => sub { mop::internal::class::get_destructor( $::SELF ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_constructor',  body => sub { mop::internal::class::get_constructor( $::SELF ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_mro',          body => sub { mop::internal::class::get_mro( $::SELF ) } ) );

    ## mutators

    $::Class->add_method( $::Method->new( name => 'set_constructor', body => sub {
        my $constructor = shift;
        mop::internal::instance::set_slot_at( $::SELF, '$constructor', \$constructor );
    }));

    $::Class->add_method( $::Method->new( name => 'set_destructor', body => sub {
        my $destructor = shift;
        mop::internal::instance::set_slot_at( $::SELF, '$destructor', \$destructor );
    }));

    $::Class->add_method( $::Method->new( name => 'add_superclass', body => sub {
        my $superclass = shift;
        push @{ $::SELF->get_superclasses } => $superclass;
    }));

    ## predicate methods ...

    $::Class->add_method( $::Method->new( name => 'is_subclass_of', body => sub { mop::internal::class::is_subclass_of( $::SELF, $_[0] ) } ) );
    $::Class->add_method( $::Method->new( name => 'equals', body => sub { mop::internal::class::equals( $::SELF, $_[0] ) } ) );

    ## class protocol

    $::Class->add_method( $::Method->new( name => 'FINALIZE', body => sub {
        $::SELF->add_superclass( $::Object )
            unless scalar @{ $::SELF->get_superclasses };
    }));

    ## add in the attributes

    $::Role->add_attribute( $::Attribute->new( name => '$name',         initial_value => \(my $class_name) ) );
    $::Role->add_attribute( $::Attribute->new( name => '$version',      initial_value => \(my $class_version) ) );
    $::Role->add_attribute( $::Attribute->new( name => '$authority',    initial_value => \(my $class_authority) ) );
    $::Role->add_attribute( $::Attribute->new( name => '$attributes',   initial_value => \({}) ) );
    $::Role->add_attribute( $::Attribute->new( name => '$methods',      initial_value => \({}) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$superclasses', initial_value => \([]) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$constructor',  initial_value => \(my $constructor) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$destructor',   initial_value => \(my $destructor) ) );

    ## --------------------------------
    ## $::Object
    ## --------------------------------

    $::Object->add_method( $::Method->new( name => 'id',    body => sub { mop::internal::instance::get_uuid( $::SELF )  } ) );
    $::Object->add_method( $::Method->new( name => 'class', body => sub { mop::internal::instance::get_class( $::SELF ) } ) );
    $::Object->add_method( $::Method->new( name => 'is_a',  body => sub { $::CLASS->equals( $_[0] ) || $::CLASS->is_subclass_of( $_[0] ) } ) );
    $::Object->add_method( $::Method->new( name => 'does',  body => sub { $::CLASS->does_role( $_[0] ) } ) );

    ## --------------------------------
    ## $::Method
    ## --------------------------------

    $::Method->add_method( $::Method->new( name => 'get_name', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' ) } ) );
    $::Method->add_method( $::Method->new( name => 'get_body', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$body' ) } ) );
    $::Method->add_method( $::Method->new( name => 'execute', body => sub {
        my ($invocant, @args) = @_;
        mop::internal::method::execute( $::SELF, $invocant, @args );
    }));

    ## --------------------------------
    ## $::Attribute
    ## --------------------------------

    $::Attribute->add_method( $::Method->new( name => 'get_name',          body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' ) } ) );
    $::Attribute->add_method( $::Method->new( name => 'get_initial_value', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$initial_value' ) } ) );
    $::Attribute->add_method( $::Method->new( name => 'get_initial_value_for_instance', body => sub {
        mop::internal::attribute::get_initial_value_for_instance( $::SELF )
    }));

    ## --------------------------------
    ## Class does Role
    ## --------------------------------
    $::Class->apply( $::Role );

    ## --------------------------------
    ## enable metaclass compatibility checks
    ## --------------------------------

    $::Class->set_constructor( $::Method->new( name => 'BUILD', body => sub {
        my @superclasses = @{ mop::internal::instance::get_slot_at( $::SELF, '$superclasses' ) };
        if ( @superclasses ) {
            my $compatible = mop::internal::class::get_compatible_class( $::CLASS, map { mop::internal::instance::get_class( $_ ) } @superclasses );
            if ( !defined( $compatible ) ) {
                die "While creating class " . $::SELF->get_name . ": "
                  . "Metaclass " . $::CLASS->get_name . " is not compatible "
                  . "with the metaclass of its superclasses: "
                  . join(', ', map { mop::internal::instance::get_class( $_ )->get_name } @superclasses);
            }
        }
    } ) );

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