package mop::bootstrap;

use strict;
use warnings;
use v5.10;

use Scalar::Util ();
use Clone        ();
use Package::Anon;

use mop::internal;


{
    my %STASHES;

    sub get_stash_for {
        my $class = shift;
        my $uuid  = mop::internal::instance::get_uuid( $class );
        $STASHES{ $uuid } //= Package::Anon->new( mop::internal::instance::get_slot_at( $class, '$name' ) );
        return $STASHES{ $uuid };
    }
}

sub init {

    ## ------------------------------------------
    ## Phase 1 : Construct the base classes
    ## ------------------------------------------

    $::Class = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Class',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        methods    => {
            'add_method' => mop::internal::create_method(
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
                            sub { mop::internal::execute_method( $method, @_ ) }
                        );
                    }
                }
            )
        }
    );

    $::Object = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Object',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
    );

    $::Method = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Method',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        superclass => $::Object,
    );

    $::Attribute = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Attribute',
        version    => '0.01',
        authority  => 'cpan:STEVAN',
        superclass => $::Object,
    );

    ## ------------------------------------------
    ## Phase 2 : Tie the knot
    ## ------------------------------------------

    mop::internal::instance::set_slot_at( $::Class, '$superclass', \$::Object );

    ## ------------------------------------------
    ## Phase 3 : Setup stashes
    ## ------------------------------------------

    # make sure to manually add the
    # add_method method to the Class
    # stash
    {
        my $method = mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'add_method'};
        get_stash_for( $::Class )->add_method(
            'add_method',
            sub { mop::internal::execute_method( $method, @_ ) }
        );
    }

    get_stash_for( $::Class )->bless( $::Object     );
    get_stash_for( $::Class )->bless( $::Class,     );
    get_stash_for( $::Class )->bless( $::Method,    );
    get_stash_for( $::Class )->bless( $::Attribute  );

    ## ------------------------------------------
    ## Phase 4 : Minimum code needed for object
    ##           construction
    ## ------------------------------------------

    # this method is needed for Class->get_mro
    $::Class->add_method(mop::internal::create_method(
        name => 'get_superclass',
        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$superclass' ) }
    ));

    # this method is needed for Class->CREATE
    $::Class->add_method(mop::internal::create_method(
        name => 'get_mro',
        body => sub {
            my $super = $::SELF->get_superclass;
            return [ $::SELF, $super ? @{ $super->get_mro } : () ]
        }
    ));

    # this method is needed for Class->CREATE
    $::Class->add_method(mop::internal::create_method(
        name => 'get_attributes',
        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$attributes' ) }
    ));

    # this method is needed for Class->CREATE
    $::Attribute->add_method(mop::internal::create_method(
        name => 'get_initial_value_for_instance',
        body => sub {
            my $value = ${ mop::internal::instance::get_slot_at( $::SELF, '$initial_value' ) };
            if ( ref $value ) {
                if ( ref $value eq 'ARRAY' || ref $value eq 'HASH' ) {
                    $value = Clone::clone( $value );
                }
                elsif ( ref $value eq 'CODE' ) {
                    $value = $value->();
                }
                else {
                    die "References of type(" . ref $value . ") are not supported";
                }
            }
            return \$value;
        }
    ));

    # this method is needed for Object->new
    $::Class->add_method(mop::internal::create_method(
        name => 'CREATE',
        body => sub {
            my $args = shift;
            my $data = {};

            mop::WALKCLASS(
                $::SELF->get_dispatcher,
                sub {
                    my $class = shift;
                    my $attrs = $class->get_attributes;
                    foreach my $attr_name ( keys %$attrs ) {
                        unless ( exists $data->{ $attr_name } ) {
                            my $param_name = $attr_name;
                            $param_name =~ s/^\$//;
                            if ( exists $args->{ $param_name } ) {
                                my $value = $args->{ $param_name };
                                $data->{ $attr_name } = \$value;
                            }
                            else {
                                $data->{ $attr_name } = $attrs->{$attr_name}->get_initial_value_for_instance(
                                    $attrs->{ $attr_name }
                                );
                            }

                        }
                    }
                }
            );

            (get_stash_for( $::SELF ) || die "Could not find stash for class(" . $::SELF->get_name . ")")->bless(
                mop::internal::instance::create( \$::SELF, $data )
            );
        }
    ));

    # this method is needed for Object->new
    $::Class->add_method(mop::internal::create_method(
        name => 'get_constructor',
        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$constructor' ) }
    ));

    # this method is needed for Object->new
    $::Class->add_method(mop::internal::create_method(
        name => 'get_dispatcher',
        body => sub {
            my $type  = shift;
            my $class = $::SELF;
            return sub { state $mro = $class->get_mro; shift @$mro } unless $type;
            return sub { state $mro = $class->get_mro; pop   @$mro } if $type eq 'reverse';
        }
    ));

    $::Object->add_method(mop::internal::create_method(
        name => 'new',
        body => sub {
            my %args = @_;
            my $self = $::SELF->CREATE( \%args );
            mop::WALKCLASS(
                $::SELF->get_dispatcher('reverse'),
                sub {
                    if ( my $constructor = $_[0]->get_constructor ) {
                        mop::internal::execute_method( $constructor, $self, \%args )
                    }
                    return;
                }
            );
            $self;
        }
    ));

    ## ------------------------------------------
    ## Phase 5 : Some fixup to make the actual
    ##           object construction work
    ## ------------------------------------------

    # this method is needed by Class->find_method
    $::Class->add_method(mop::internal::create_method(
        name => 'get_methods',
        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$methods' ) }
    ));

    # this method is needed to find Object->new (SEE BELOW)
    $::Class->add_method(mop::internal::create_method( name => 'find_method', body => sub {
        my $method_name = shift;
        $::SELF->get_methods->{ $method_name };
    }));

    {
        ## ------------------------------------------
        ## NOTE:
        ## ------------------------------------------
        ## Add the Object->new method to the Class
        ## stash, so we can use it to construct things
        ## with it from now on.
        ## ------------------------------------------

        my $method = $::Object->find_method('new');
        get_stash_for( $::Class )->add_method(
            'new',
            sub { mop::internal::execute_method( $method, @_ ) }
        );
    }

    # this method is needed by Class->add_attribute
    $::Attribute->add_method(mop::internal::create_method(
        name => 'get_name',
        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' ) }
    ));

    # this method is needed to add the attributes
    # to Attribute and Method (SEE BELOW)
    $::Class->add_method(mop::internal::create_method( name => 'add_attribute', body => sub {
        my $attr = shift;
        $::SELF->get_attributes->{ $attr->get_name } = $attr;
    }));

    ## ------------------------------------------
    ## NOTE:
    ## ------------------------------------------
    ## But before we can construct an Attribute
    ## we need to define its own attributes, and
    ## make sure they are blessed properly. This
    ## is a metacirculatity issue because we need
    ## to make proper attributes for the Attribute
    ## class.
    ## ------------------------------------------

    $::Attribute->add_attribute(
        get_stash_for( $::Attribute )->bless(
            mop::internal::create_attribute( name => '$name', initial_value => \(my $attribute_name))
        )
    );

    $::Attribute->add_attribute(
        get_stash_for( $::Attribute )->bless(
            mop::internal::create_attribute( name => '$initial_value', initial_value => \(my $initial_value))
        )
    );

    # Horray, Now we can actually create objects!

    $::Method->add_attribute( $::Attribute->new( name => '$name', initial_value => \(my $method_name)) );
    $::Method->add_attribute( $::Attribute->new( name => '$body', initial_value => \(my $method_body)) );

    ## ------------------------------------------
    ## Phase 6 : Create the rest of the MOP
    ## ------------------------------------------

    ## --------------------------------
    ## $::Class
    ## --------------------------------

    ## accessors
    $::Class->add_method( $::Method->new( name => 'attribute_class', body => sub { $::Attribute }));
    $::Class->add_method( $::Method->new( name => 'method_class',    body => sub { $::Method    }));
    $::Class->add_method( $::Method->new( name => 'get_name',        body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' )       }));
    $::Class->add_method( $::Method->new( name => 'get_version',     body => sub { mop::internal::instance::get_slot_at( $::SELF, '$version' )    }));
    $::Class->add_method( $::Method->new( name => 'get_authority',   body => sub { mop::internal::instance::get_slot_at( $::SELF, '$authority' )  }));
    $::Class->add_method( $::Method->new( name => 'get_destructor',  body => sub { mop::internal::instance::get_slot_at( $::SELF, '$destructor' ) }));

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

    ## predicate methods for Class
    $::Class->add_method( $::Method->new(
        name => 'equals',
        body => sub {
            my $other = shift;
            return mop::internal::instance::get_uuid( $::SELF ) eq mop::internal::instance::get_uuid( $other );
        }
    ));
    $::Class->add_method( $::Method->new(
        name => 'is_subclass_of',
        body => sub {
            my $super = shift;
            my @mro = @{ $::SELF->get_mro };
            shift @mro;
            return scalar grep { $super->equals( $_ ) } @mro;
        }
    ));

    ## FINALIZE protocol
    $::Class->add_method( $::Method->new( name => 'FINALIZE', body => sub {
        $::SELF->set_superclass( $::Object )
            unless $::SELF->get_superclass;

        # pre-compute the vtable
        my $stash      = get_stash_for( $::SELF );
        my $dispatcher = $::SELF->get_dispatcher;

        mop::WALKCLASS(
            $dispatcher,
            sub {
                my $c = shift;
                my $methods = $c->get_methods;
                foreach my $name ( keys %$methods ) {
                    my $method = $methods->{ $name };
                    $stash->add_method(
                        $name,
                        sub { mop::internal::execute_method( $method, @_ ) }
                    ) unless exists $stash->{ $name };
                }
            }
        );

        # NOTE:
        # this is totally wrong
        # - SL
        $stash->add_method('NEXTMETHOD' => sub {
            my $invocant    = shift;
            my $method_name = (split '::' => ((caller(1))[3]))[-1];
            my $class       = mop::internal::instance::get_class( $invocant );
            my $dispatcher  = $class->get_dispatcher;
            mop::WALKMETH( $dispatcher, $method_name ); # discard the first one ...
            mop::internal::execute_method( mop::WALKMETH( $dispatcher, $method_name ), $invocant, @_ );
        });

        $stash->add_method('DESTROY' => sub {
            my $invocant = shift;
            my $class    = mop::internal::instance::get_class( $invocant );
            return unless $class; # likely in global destruction ...
            mop::WALKCLASS(
                $class->get_dispatcher(),
                sub {
                    if ( my $destructor = $_[0]->get_destructor ) {
                        mop::internal::execute_method( $destructor, $invocant )
                    }
                    return;
                }
            );
        });

        return $stash;

    }));

    # ...

    $::Class->add_method( $::Method->new(
        name => 'get_compatible_class',
        body => sub {
            my $class = shift;
            # replace the class with a subclass of itself
            return $class  if $class->is_subclass_of( $::SELF );
            # it's already okay
            return $::SELF if $::SELF->is_subclass_of( $class ) || $class->equals( $::SELF );
            # reconciling this group of metaclasses isn't possible
            return;
        }
    ));

    ## check metaclass compat in Class->BUILD
    $::Class->set_constructor( $::Method->new(
        name => 'BUILD',
        body => sub {
            my $superclass = $::SELF->get_superclass;
            if ( $superclass ) {
                my $superclass_class = mop::internal::instance::get_class( $superclass );
                my $compatible       = $::CLASS->get_compatible_class( $superclass_class );
                if ( !defined( $compatible ) ) {
                    die "While creating class " . $::SELF->get_name . ": "
                      . "Metaclass " . $::CLASS->get_name . " is not compatible "
                      . "with the metaclass of its superclass: "
                      . $superclass_class->get_name;
                }
            }
        }
    ));

    ## add in the attributes
    $::Class->add_attribute( $::Attribute->new( name => '$name',        initial_value => \(my $class_name)));
    $::Class->add_attribute( $::Attribute->new( name => '$version',     initial_value => \(my $class_version)));
    $::Class->add_attribute( $::Attribute->new( name => '$authority',   initial_value => \(my $class_authority)));
    $::Class->add_attribute( $::Attribute->new( name => '$superclass',  initial_value => \(my $superclass)));
    $::Class->add_attribute( $::Attribute->new( name => '$attributes',  initial_value => \({})));
    $::Class->add_attribute( $::Attribute->new( name => '$methods',     initial_value => \({})));
    $::Class->add_attribute( $::Attribute->new( name => '$constructor', initial_value => \(my $constructor)));
    $::Class->add_attribute( $::Attribute->new( name => '$destructor',  initial_value => \(my $destructor)));

    ## --------------------------------
    ## $::Object
    ## --------------------------------

    $::Object->add_method( $::Method->new( name => 'id',    body => sub { mop::internal::instance::get_uuid( $::SELF )  }));
    $::Object->add_method( $::Method->new( name => 'class', body => sub { mop::internal::instance::get_class( $::SELF ) }));
    $::Object->add_method( $::Method->new( name => 'is_a',  body => sub { $::CLASS->equals( $_[0] ) || $::CLASS->is_subclass_of( $_[0] ) }));

    ## --------------------------------
    ## $::Method
    ## --------------------------------

    $::Method->add_method( $::Method->new( name => 'get_name', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$name' ) }));
    $::Method->add_method( $::Method->new( name => 'get_body', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$body' ) }));
    $::Method->add_method( $::Method->new( name => 'execute', body => sub {
        my ($invocant, @args) = @_;
        mop::internal::execute_method( $::SELF, $invocant, @args );
    }));

    ## --------------------------------
    ## $::Attribute
    ## --------------------------------

    $::Attribute->add_method( $::Method->new( name => 'get_initial_value', body => sub { mop::internal::instance::get_slot_at( $::SELF, '$initial_value' ) }));

    ## --------------------------------
    ## Phase 7 : Bootstrap cleanup
    ## --------------------------------

    # grab a few useful stashes here ...
    my $Class_stash     = get_stash_for( $::Class );
    my $Method_stash    = get_stash_for( $::Method );
    my $Attribute_stash = get_stash_for( $::Attribute );

    ## --------------------------------
    ## go through all the classes and
    ## bless the methods and attributes
    ## into the proper stashes as needed
    ## --------------------------------

    foreach my $class ( $::Object, $::Class, $::Method, $::Attribute ) {
        my $methods = mop::internal::instance::get_slot_at( $class, '$methods' );
        foreach my $method ( values %$methods ) {
            $Method_stash->bless( $method )
                unless Scalar::Util::blessed( $method );
        }
        my $attributes = mop::internal::instance::get_slot_at( $class, '$attributes' );
        foreach my $attribute ( values %$attributes ) {
            $Attribute_stash->bless( $attribute )
                unless Scalar::Util::blessed( $attribute );
        }
    }

    ## --------------------------------
    ## make sure Class, Method and
    ## Attribute has the Object
    ## methods in the stash too
    ## --------------------------------

    {
        my $methods = mop::internal::instance::get_slot_at( $::Object, '$methods' );
        foreach my $method_name ( keys %$methods ) {
            my $method = $methods->{ $method_name };
            $Class_stash->add_method(
                $method_name,
                sub { mop::internal::execute_method( $method, @_ ) }
            );
            $Method_stash->add_method(
                $method_name,
                sub { mop::internal::execute_method( $method, @_ ) }
            );
            $Attribute_stash->add_method(
                $method_name,
                sub { mop::internal::execute_method( $method, @_ ) }
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
