package mop::bootstrap;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;
use mop::internal::attribute;
use mop::internal::method;
use mop::internal::dispatcher;


{
    my %STASHES;

    sub get_stash_for {
        my $class = shift;
        my $uuid  = mop::internal::instance::get_uuid( $class );
        return $STASHES{ $uuid } if exists $STASHES{ $uuid };
        return;
    }

    sub generate_stash_for {
        my $class = shift;
        my $uuid  = mop::internal::instance::get_uuid( $class );
        $STASHES{ $uuid } = mop::internal::dispatcher::GENSTASH( $class );
    }
}

sub init {

    ## --------------------------------
    ## Create our classes
    ## --------------------------------

    $::Class = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Class',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        attributes => {},
        methods    => {
            'add_method' => mop::internal::method::create(
                name => 'add_method',
                body => sub {
                    my $method = shift;
                    mop::internal::instance::get_slot_at( $::SELF, '$methods' )->{
                        mop::internal::instance::get_slot_at( $method, '$name' )
                    } = $method;

                    if ( my $stash = get_stash_for( $::SELF ) ) {
                        # NOTE:
                        # we won't always have a stash
                        # because it is created at FINALIZE
                        # and not when the class itself is
                        # created.
                        # - SL
                        $stash->add_method(
                            mop::internal::instance::get_slot_at( $method, '$name' ),
                            sub { mop::internal::method::execute( $method, @_ ) }
                        );
                    }
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

                    (get_stash_for( $::SELF ) || die "Could not find stash for class(" . $::SELF->get_name . ")")->bless(
                        mop::internal::instance::create( \$::SELF, $data )
                    );
                }
            )
        }
    );

    $::Object = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Object',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        attributes => {},
        methods    => {
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
        class      => \$::Class,
        name       => 'Method',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        superclass => $::Object,
        methods    => {},
        attributes => {
            '$name' => mop::internal::attribute::create( name => '$name', initial_value => \(my $method_name) ),
            '$body' => mop::internal::attribute::create( name => '$body', initial_value => \(my $method_body) ),
        },
    );

    $::Attribute = mop::internal::class::create(
        class      => \$::Class,
        name       => 'Attribute',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        superclass => $::Object,
        methods    => {},
        attributes => {
            '$name'          => mop::internal::attribute::create( name => '$name',          initial_value => \(my $attribute_name) ),
            '$initial_value' => mop::internal::attribute::create( name => '$initial_value', initial_value => \(my $initial_value)  ),
        },
    );

    ## --------------------------------
    ## START BOOTSTRAP
    ## --------------------------------

    mop::internal::instance::set_slot_at( $::Class, '$superclass', \$::Object );

    generate_stash_for( $::Object    );
    generate_stash_for( $::Class     );
    generate_stash_for( $::Method    );
    generate_stash_for( $::Attribute );

    get_stash_for( $::Class )->bless( $::Object    );
    get_stash_for( $::Class )->bless( $::Class,    );
    get_stash_for( $::Class )->bless( $::Method,   );
    get_stash_for( $::Class )->bless( $::Attribute );

    get_stash_for( $::Method )->bless( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'add_method'} );
    get_stash_for( $::Method )->bless( mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'CREATE'}     );
    get_stash_for( $::Method )->bless( mop::internal::instance::get_slot_at( $::Object, '$methods' )->{'new'}       );

    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Method, '$attributes' )->{'$name'}             );
    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Method, '$attributes' )->{'$body'}             );
    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$name'}          );
    get_stash_for( $::Attribute )->bless( mop::internal::instance::get_slot_at( $::Attribute, '$attributes' )->{'$initial_value'} );

    ## --------------------------------
    ## $::Class
    ## --------------------------------

    ## accessors

    $::Class->add_method( $::Method->new( name => 'get_name',        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' )       } ) );
    $::Class->add_method( $::Method->new( name => 'get_version',     body => sub { mop::internal::instance::get_slot_at( $::SELF, '$version' )    } ) );
    $::Class->add_method( $::Method->new( name => 'get_authority',   body => sub { mop::internal::instance::get_slot_at( $::SELF, '$authority' )  } ) );
    $::Class->add_method( $::Method->new( name => 'get_superclass',  body => sub { mop::internal::instance::get_slot_at( $::SELF, '$superclass' ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_methods',     body => sub { mop::internal::instance::get_slot_at( $::SELF, '$methods' )    } ) );
    $::Class->add_method( $::Method->new( name => 'get_attributes',  body => sub { mop::internal::instance::get_slot_at( $::SELF, '$attributes' ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_destructor',  body => sub { mop::internal::class::get_destructor( $::SELF ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_constructor', body => sub { mop::internal::class::get_constructor( $::SELF ) } ) );
    $::Class->add_method( $::Method->new( name => 'get_mro',         body => sub { mop::internal::class::get_mro( $::SELF ) } ) );
    $::Class->add_method( $::Method->new( name => 'attribute_class', body => sub { $::Attribute } ) );
    $::Class->add_method( $::Method->new( name => 'method_class',    body => sub { $::Method } ) );
    $::Class->add_method( $::Method->new( name => 'find_method', body => sub {
        my $method_name = shift;
        mop::internal::class::find_method( $::SELF, $method_name )
    }));

    ## mutators

    $::Class->add_method( $::Method->new( name => 'set_constructor', body => sub {
        my $constructor = shift;
        mop::internal::instance::set_slot_at( $::SELF, '$constructor', \$constructor );
    }));

    $::Class->add_method( $::Method->new( name => 'set_destructor', body => sub {
        my $destructor = shift;
        mop::internal::instance::set_slot_at( $::SELF, '$destructor', \$destructor );
    }));

    $::Class->add_method( $::Method->new( name => 'set_superclass', body => sub {
        my $superclass = shift;
        mop::internal::instance::set_slot_at( $::SELF, '$superclass', \$superclass );
    }));
    $::Class->add_method( $::Method->new( name => 'add_attribute', body => sub {
        my $attr = shift;
        $::SELF->get_attributes->{ mop::internal::instance::get_slot_at( $attr, '$name' ) } = $attr;
    }));

    ## predicate methods ...

    $::Class->add_method( $::Method->new( name => 'is_subclass_of', body => sub { mop::internal::class::is_subclass_of( $::SELF, $_[0] ) } ) );
    $::Class->add_method( $::Method->new( name => 'equals', body => sub { mop::internal::class::equals( $::SELF, $_[0] ) } ) );

    ## class protocol

    $::Class->add_method( $::Method->new( name => 'FINALIZE', body => sub {
        $::SELF->set_superclass( $::Object )
            unless $::SELF->get_superclass;

        # pre-compute the vtable
        generate_stash_for( $::SELF );
    }));

    ## add in the attributes

    $::Class->add_attribute( $::Attribute->new( name => '$name',        initial_value => \(my $class_name) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$version',     initial_value => \(my $class_version) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$authority',   initial_value => \(my $class_authority) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$superclass',  initial_value => \(my $superclass) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$attributes',  initial_value => \sub { +{} } ) );
    $::Class->add_attribute( $::Attribute->new( name => '$methods',     initial_value => \sub { +{} } ) );
    $::Class->add_attribute( $::Attribute->new( name => '$constructor', initial_value => \(my $constructor) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$destructor',  initial_value => \(my $destructor) ) );

    ## --------------------------------
    ## $::Object
    ## --------------------------------

    $::Object->add_method( $::Method->new( name => 'id',    body => sub { mop::internal::instance::get_uuid( $::SELF )  } ) );
    $::Object->add_method( $::Method->new( name => 'class', body => sub { mop::internal::instance::get_class( $::SELF ) } ) );
    $::Object->add_method( $::Method->new( name => 'is_a',  body => sub { $::CLASS->equals( $_[0] ) || $::CLASS->is_subclass_of( $_[0] ) } ) );

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
    ## enable metaclass compatibility checks
    ## --------------------------------

    $::Class->set_constructor( $::Method->new( name => 'BUILD', body => sub {
        my $superclass = mop::internal::instance::get_slot_at( $::SELF, '$superclass' );
        if ( $superclass ) {
            my $compatible = mop::internal::class::get_compatible_class( $::CLASS, mop::internal::instance::get_class( $superclass ) );
            if ( !defined( $compatible ) ) {
                die "While creating class " . $::SELF->get_name . ": "
                  . "Metaclass " . $::CLASS->get_name . " is not compatible "
                  . "with the metaclass of its superclass: "
                  . mop::internal::instance::get_class( $superclass )->get_name;
            }
        }
    } ) );

    ## --------------------------------
    ## make sure Class, Method and
    ## Attribute has the Object
    ## methods in the stash too
    ## --------------------------------

    {
        my $methods = mop::internal::instance::get_slot_at( $::Object, '$methods' );
        foreach my $method_name ( keys %$methods ) {
            my $method = $methods->{ $method_name };
            get_stash_for( $::Class )->add_method(
                mop::internal::instance::get_slot_at( $method, '$name' ),
                sub { mop::internal::method::execute( $method, @_ ) }
            );
            get_stash_for( $::Method )->add_method(
                mop::internal::instance::get_slot_at( $method, '$name' ),
                sub { mop::internal::method::execute( $method, @_ ) }
            );
            get_stash_for( $::Attribute )->add_method(
                mop::internal::instance::get_slot_at( $method, '$name' ),
                sub { mop::internal::method::execute( $method, @_ ) }
            );
        }
    }


    ## --------------------------------
    ## END BOOTSTRAP
    ## --------------------------------

    return;
}

1;

__END__

=pod

=head1 NAME

mop::internal::bootstrap

=head1 DESCRIPTION

The bootstrapping process is important, but a little ugly and
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
minimums so that there is less to overwrite in the MOP bootstrap
that we do later on.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
