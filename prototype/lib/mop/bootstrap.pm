package mop::bootstrap;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();

use mop::internal;

sub init {

    ## ------------------------------------------
    ## Phase 1 : Construct the core classes
    ## ------------------------------------------

    $::Class = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Class',
        version    => $VERSION,
        authority  => $AUTHORITY,
        methods    => {
            'add_method' => mop::internal::create_method(
                name => 'add_method',
                body => sub {
                    my $method = shift;
                    my $name   = mop::internal::instance::get_slot_at( $method, '$name' );
                    mop::internal::instance::get_slot_at( $::SELF, '$methods' )->{ $name } = $method;

                    # this is temporary for bootstrapping, so that we don't
                    # have to keep manually updating the stash in order to use
                    # newly installed methods. it will be removed at the end
                    # of the bootstrap process.
                    my $stash = mop::internal::get_stash_for( $::SELF );
                    mop::internal::get_stash_for( $::Method )->bless( $method )
                        unless Scalar::Util::blessed( $method );
                    $stash->add_method( $name, sub { $method->execute( @_ ) } );
                }
            )
        }
    );

    $::Object = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Object',
        version    => $VERSION,
        authority  => $AUTHORITY,
    );

    $::Method = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Method',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => $::Object,
        methods    => {
            # We need to define the execute method
            # of the Method object very early on
            # so that *most* of our method calls
            # can use this, and any that won't
            # use it will eventually get fixed up
            # by the end of the bootstrapping.
            'execute' => mop::internal::create_method(
                name => 'execute',
                body => sub { mop::internal::execute_method( $::SELF, @_ ) }
            )
        }
    );

    $::Attribute = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Attribute',
        version    => $VERSION,
        authority  => $AUTHORITY,
        superclass => $::Object,
    );

    ## ------------------------------------------
    ## Phase 2 : Tie the knot
    ## ------------------------------------------

    mop::internal::instance::set_slot_at( $::Class, '$superclass', \$::Object );

    ## ------------------------------------------
    ## Phase 3 : Setup stashes
    ## ------------------------------------------

    mop::internal::get_stash_for( $::Class )->bless( $::Object     );
    mop::internal::get_stash_for( $::Class )->bless( $::Class,     );
    mop::internal::get_stash_for( $::Class )->bless( $::Method,    );
    mop::internal::get_stash_for( $::Class )->bless( $::Attribute  );

    # make sure to manually add the
    # add_method method to the Class
    # stash. This still uses the
    # internal method execution, but
    # we will fix that in the final
    # phase of the bootstrap.
    {
        my $method = mop::internal::instance::get_slot_at( $::Class, '$methods' )->{'add_method'};
        mop::internal::get_stash_for( $::Class )->add_method(
            'add_method',
            sub { mop::internal::execute_method( $method, @_ ) }
        );
    }

    # We add this to the stash manually so
    # as to avoid meta-circularity issues
    # inside Class->add_method.
    {
        my $method = mop::internal::instance::get_slot_at( $::Method, '$methods' )->{ 'execute' };
        mop::internal::get_stash_for( $::Method )->add_method(
            'execute',
            sub { mop::internal::execute_method( $method, @_ ) }
        );
    }

    ## ------------------------------------------
    ## Phase 4 : Minimum code needed for object
    ##           construction
    ## ------------------------------------------

    # helpers for creating some methods
    my $reader = sub {
        my ($slot) = @_;
        sub {
            mop::internal::instance::get_slot_at( $::SELF, $slot );
        };
    };
    my $writer = sub {
        my ($slot) = @_;
        sub {
            my $val = shift;
            mop::internal::instance::set_slot_at( $::SELF, $slot, \$val );
        };
    };

    # this method is needed for Class->get_mro
    $::Class->add_method(mop::internal::create_method(
        name => 'get_superclass',
        body => $reader->( '$superclass' ),
    ));

    # this method is needed for Attribute->get_initial_value_for_instance
    $::Attribute->add_method(mop::internal::create_method(
        name => 'get_initial_value',
        body => $reader->( '$initial_value' )
    ));

    # this method is needed for Attribute->get_param_name
    $::Attribute->add_method(mop::internal::create_method(
        name => 'get_name',
        body => $reader->( '$name' ),
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
        body => $reader->( '$attributes' ),
    ));

    # this method is needed for Class->CREATE
    $::Attribute->add_method(mop::internal::create_method(
        name => 'get_initial_value_for_instance',
        body => sub {
            my $value = ${ $::SELF->get_initial_value };
            if ( ref $value ) {
                if ( ref $value eq 'CODE' ) {
                    $value = $value->();
                }
                else {
                    die "References of type(" . ref $value . ") are not supported";
                }
            }
            return \$value;
        }
    ));

    # this method is needed for Class->CREATE
    $::Attribute->add_method(mop::internal::create_method(
        name => 'get_param_name',
        body => sub {
            my $name = $::SELF->get_name;
            $name =~ s/^\$//;
            $name;
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
                            my $param_name = $attrs->{ $attr_name }->get_param_name;
                            if ( exists $args->{ $param_name } ) {
                                my $value = $args->{ $param_name };
                                $data->{ $attr_name } = \$value;
                            }
                            else {
                                $data->{ $attr_name } = $attrs->{$attr_name}->get_initial_value_for_instance;
                            }

                        }
                    }
                }
            );

            (mop::internal::get_stash_for( $::SELF ) || die "Could not find stash for class(" . $::SELF->get_name . ")")->bless(
                mop::internal::instance::create( \$::SELF, $data )
            );
        }
    ));

    # this method is needed for Object->new
    $::Class->add_method(mop::internal::create_method(
        name => 'get_constructor',
        body => $reader->( '$constructor' ),
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
                sub { ( $_[0]->get_constructor || return )->execute( $self, \%args ); return }
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
        body => $reader->( '$methods' ),
    ));

    # this method is needed to find Object->new (SEE BELOW)
    $::Class->add_method(mop::internal::create_method(
        name => 'find_method',
        body => sub {
            my $method_name = shift;
            $::SELF->get_methods->{ $method_name };
        },
    ));

    {
        ## ------------------------------------------
        ## NOTE:
        ## ------------------------------------------
        ## Add the Object->new method to the Class
        ## stash, so we can use it to construct things
        ## with it from now on.
        ## ------------------------------------------

        my $method = mop::internal::get_stash_for( $::Method )->bless(
            $::Object->find_method('new')
        );
        mop::internal::get_stash_for( $::Class )->add_method(
            'new',
            sub { $method->execute( @_ ) }
        );
    }

    # this method is needed to add the attributes
    # to Attribute and Method (SEE BELOW)
    $::Class->add_method(mop::internal::create_method(
        name => 'add_attribute',
        body => sub {
            my $attr = shift;
            $::SELF->get_attributes->{ $attr->get_name } = $attr;
        },
    ));

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
        mop::internal::get_stash_for( $::Attribute )->bless(
            mop::internal::create_attribute( name => '$name', initial_value => \(my $attribute_name))
        )
    );

    $::Attribute->add_attribute(
        mop::internal::get_stash_for( $::Attribute )->bless(
            mop::internal::create_attribute( name => '$initial_value', initial_value => \(my $initial_value))
        )
    );

    # Horray, Now we can actually create objects!

    $::Method->add_attribute( $::Attribute->new( name => '$name', initial_value => \(my $method_name) ) );
    $::Method->add_attribute( $::Attribute->new( name => '$body', initial_value => \(my $method_body) ) );

    ## ------------------------------------------
    ## Phase 6 : Create the rest of the MOP
    ## ------------------------------------------

    ## --------------------------------
    ## $::Class
    ## --------------------------------

    ## accessors
    $::Class->add_method( $::Method->new( name => 'attribute_class',   body => sub { $::Attribute } ) );
    $::Class->add_method( $::Method->new( name => 'method_class',      body => sub { $::Method    } ) );
    $::Class->add_method( $::Method->new( name => 'base_object_class', body => sub { $::Object    } ) );
    $::Class->add_method( $::Method->new( name => 'get_name',          body => $reader->( '$name' )       ) );
    $::Class->add_method( $::Method->new( name => 'get_version',       body => $reader->( '$version' )    ) );
    $::Class->add_method( $::Method->new( name => 'get_authority',     body => $reader->( '$authority' )  ) );
    $::Class->add_method( $::Method->new( name => 'get_destructor',    body => $reader->( '$destructor' ) ) );

    $::Class->add_method( $::Method->new( name => 'find_attribute',    body => sub { $::SELF->get_attributes->{ $_[0] } } ) );

    ## mutators
    $::Class->add_method( $::Method->new( name => 'set_constructor', body => $writer->( '$constructor' ) ) );
    $::Class->add_method( $::Method->new( name => 'set_destructor',  body => $writer->( '$destructor'  ) ) );
    $::Class->add_method( $::Method->new( name => 'set_superclass',  body => $writer->( '$superclass'  ) ) );

    ## predicate methods for Class
    $::Class->add_method( $::Method->new(
        name => 'equals',
        body => sub {
            my $other = shift;
            return mop::internal::instance::get_uuid( $::SELF ) eq mop::internal::instance::get_uuid( $other );
        },
    ) );
    $::Class->add_method( $::Method->new(
        name => 'is_subclass_of',
        body => sub {
            my $super = shift;
            my @mro = @{ $::SELF->get_mro };
            shift @mro;
            return scalar grep { $super->equals( $_ ) } @mro;
        },
    ) );

    ## FINALIZE protocol
    $::Class->add_method( $::Method->new(
        name => 'FINALIZE',
        body => sub {
            my $stash      = mop::internal::get_stash_for( $::SELF );
            my $dispatcher = $::SELF->get_dispatcher;

            %$stash = ();

            mop::WALKCLASS(
                $dispatcher,
                sub {
                    my $c = shift;
                    my $methods = $c->get_methods;
                    foreach my $name ( keys %$methods ) {
                        my $method = $methods->{ $name };
                        $stash->add_method(
                            $name,
                            sub { $method->execute( @_ ) }
                        ) unless exists $stash->{ $name };
                    }
                }
            );

            $stash->add_method('DESTROY' => sub {
                my $invocant = shift;
                my $class    = mop::internal::instance::get_class( $invocant );
                return unless $class; # likely in global destruction ...
                mop::WALKCLASS(
                    $class->get_dispatcher(),
                    sub { ( $_[0]->get_destructor || return )->execute( $invocant ); return }
                );
            });
        },
    ) );

    ## check metaclass compat in Class->BUILD
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
        },
    ) );
    $::Class->set_constructor( $::Method->new(
        name => 'BUILD',
        body => sub {
            $::SELF->set_superclass( $::SELF->base_object_class )
                unless $::SELF->get_superclass;
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
        },
    ) );

    ## add in the attributes
    $::Class->add_attribute( $::Attribute->new( name => '$name',        initial_value => \(my $class_name)      ) );
    $::Class->add_attribute( $::Attribute->new( name => '$version',     initial_value => \(my $class_version)   ) );
    $::Class->add_attribute( $::Attribute->new( name => '$authority',   initial_value => \(my $class_authority) ) );
    $::Class->add_attribute( $::Attribute->new( name => '$superclass',  initial_value => \(my $superclass)      ) );
    $::Class->add_attribute( $::Attribute->new( name => '$attributes',  initial_value => \sub { +{} }           ) );
    $::Class->add_attribute( $::Attribute->new( name => '$methods',     initial_value => \sub { +{} }           ) );
    $::Class->add_attribute( $::Attribute->new( name => '$constructor', initial_value => \(my $constructor)     ) );
    $::Class->add_attribute( $::Attribute->new( name => '$destructor',  initial_value => \(my $destructor)      ) );

    ## --------------------------------
    ## $::Object
    ## --------------------------------

    $::Object->add_method( $::Method->new( name => 'isa',  body => sub { $::CLASS->equals( $_[0] ) || $::CLASS->is_subclass_of( $_[0] ) } ) );

    ## --------------------------------
    ## $::Method
    ## --------------------------------

    $::Method->add_method( $::Method->new( name => 'get_name', body => $reader->( '$name' ) ) );
    $::Method->add_method( $::Method->new( name => 'get_body', body => $reader->( '$body' ) ) );

    ## --------------------------------
    ## $::Attribute
    ## --------------------------------


    ## --------------------------------
    ## Phase 7 : Bootstrap cleanup
    ## --------------------------------

    # grab a few useful stashes here ...
    my $Class_stash     = mop::internal::get_stash_for( $::Class );
    my $Method_stash    = mop::internal::get_stash_for( $::Method );
    my $Attribute_stash = mop::internal::get_stash_for( $::Attribute );

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
                sub { $method->execute( @_ ) }
            );
            $Method_stash->add_method(
                $method_name,
                sub { $method->execute( @_ ) }
            );
            $Attribute_stash->add_method(
                $method_name,
                sub { $method->execute( @_ ) }
            );
        }
    }

    ## --------------------------------
    ## ensure that for actual classes,
    ## nothing is added to the stash
    ## until FINALIZE time.
    ## this also overrides add_method
    ## in Class's stash with a version
    ## that actually calls ->execute,
    ## rather than execute_method.
    ## --------------------------------

    $::Class->add_method( $::Method->new( name => 'add_method', body => sub {
        my $method = shift;
        $::SELF->get_methods->{ $method->get_name } = $method;
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

mop::internal::bootstrap - The bootstrap for the p5-mop

=head1 DESCRIPTION

The bootstrapping process is important, but as with most
bootstrapping is a little ugly and manual. The main goal
of the bootstrap is to define the class Class as well as
the class Object, and to "tie the knot" such that the
following things are true:

  Class is an instance of Class
  Object is an instance of Class
  Class is a subclass of Object

This is what will give us our desired "turtles all the way down"
metacircularity.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
