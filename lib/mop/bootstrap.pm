package mop::bootstrap;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();
use version ();

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

    $::Role = mop::internal::create_class(
        class      => \$::Class,
        name       => 'Role',
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
    mop::internal::get_stash_for( $::Class )->bless( $::Role       );

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

    # this method is needed for Class->create_instance
    $::Class->add_method(mop::internal::create_method(
        name => 'get_mro',
        body => sub {
            my $super = $::SELF->get_superclass;
            return [ $::SELF, $super ? @{ $super->get_mro } : () ]
        }
    ));

    # this method is needed for Class->get_all_attributes
    $::Class->add_method(mop::internal::create_method(
        name => 'get_local_attributes',
        body => $reader->( '$attributes' ),
    ));

    # this method is needed for Class->create_instance
    $::Class->add_method(mop::internal::create_method(
        name => 'get_all_attributes',
        body => sub {
            my %attrs;
            mop::WALKCLASS(
                $::SELF->get_dispatcher('reverse'),
                sub {
                    my $class = shift;
                    %attrs = (
                        %attrs,
                        %{ $class->get_local_attributes },
                    );
                }
            );

            return \%attrs;
        },
    ));

    # this method is needed for Class->create_instance
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

    # this method is needed for Class->create_instance
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
        name => 'create_instance',
        body => sub {
            my $args = shift;
            my $data = {};

            my $attrs = $::SELF->get_all_attributes;
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

    $::Class->add_method(mop::internal::create_method(
        name => 'new',
        body => sub {
            my %args = @_;
            my $self = $::SELF->create_instance( \%args );
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

    # this method is needed to add the attributes
    # to Attribute and Method (SEE BELOW)
    $::Class->add_method(mop::internal::create_method(
        name => 'add_attribute',
        body => sub {
            my $attr = shift;
            $::SELF->get_local_attributes->{ $attr->get_name } = $attr;
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

    ## accessors
    $::Class->add_method( $::Method->new( name => 'attribute_class',   body => sub { $::Attribute } ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'method_class',      body => sub { $::Method    } ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'base_object_class', body => sub { $::Object    } ) );

    $::Class->add_method( $::Method->new( name => 'get_name',          body => $reader->( '$name' )       ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'get_version',       body => $reader->( '$version' )    ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'get_authority',     body => $reader->( '$authority' )  ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'get_local_methods', body => $reader->( '$methods' )    ) );
    $::Class->add_method( $::Method->new( name => 'get_destructor',    body => $reader->( '$destructor' ) ) );

    $::Class->add_method( $::Method->new(
        name => 'get_all_methods',
        body => sub {
            my %methods;
            mop::WALKCLASS(
                $::SELF->get_dispatcher('reverse'),
                sub {
                    my $class = shift;
                    %methods = (
                        %methods,
                        %{ $class->get_local_methods },
                    );
                }
            );

            return \%methods;
        },
    ));

    $::Method->add_method( $::Method->new( name => 'get_name', body => $reader->( '$name' ) ) );
    $::Method->add_method( $::Method->new( name => 'get_body', body => $reader->( '$body' ) ) );

    $::Class->add_method( $::Method->new( name => 'find_attribute', body => sub { $::SELF->get_all_attributes->{ $_[0] } } ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'find_method',    body => sub { $::SELF->get_all_methods->{ $_[0] } }    ) ); # FIXME: can come from Role


    ## mutators
    $::Class->add_method( $::Method->new( name => 'set_version',     body => $writer->( '$version' )     ) ); # FIXME: can come from Role
    $::Class->add_method( $::Method->new( name => 'set_constructor', body => $writer->( '$constructor' ) ) );
    $::Class->add_method( $::Method->new( name => 'set_destructor',  body => $writer->( '$destructor'  ) ) );
    $::Class->add_method( $::Method->new( name => 'set_superclass',  body => $writer->( '$superclass'  ) ) );

    ## clone
    $::Method->add_method( $::Method->new(
        name => 'clone',
        body => sub {
            my %params = (
                (map {
                    $_->get_param_name => mop::internal::instance::get_slot_at(
                        $::SELF, $_->get_name
                    )
                } values %{ $::CLASS->get_all_attributes }),
                @_,
            );
            return $::CLASS->new(%params);
        },
    ) );
    $::Attribute->add_method( $::Method->find_method('clone')->clone );

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

            my $methods = $::SELF->get_all_methods;
            foreach my $name ( keys %$methods ) {
                my $method = $methods->{ $name };
                $stash->add_method(
                    $name,
                    sub { $method->execute( @_ ) }
                ) unless exists $stash->{ $name };
            }

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

            my $v = $::SELF->get_version;
            $::SELF->set_version(version->parse($v))
                if defined $v;

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
    $::Class->add_attribute( $::Attribute->new( name => '$name',        initial_value => \(my $class_name)      ) ); # FIXME: can come from Role
    $::Class->add_attribute( $::Attribute->new( name => '$version',     initial_value => \(my $class_version)   ) ); # FIXME: can come from Role
    $::Class->add_attribute( $::Attribute->new( name => '$authority',   initial_value => \(my $class_authority) ) ); # FIXME: can come from Role
    $::Class->add_attribute( $::Attribute->new( name => '$superclass',  initial_value => \(my $superclass)      ) );
    $::Class->add_attribute( $::Attribute->new( name => '$attributes',  initial_value => \sub { +{} }           ) ); # FIXME: can come from Role
    $::Class->add_attribute( $::Attribute->new( name => '$methods',     initial_value => \sub { +{} }           ) ); # FIXME: can come from Role
    $::Class->add_attribute( $::Attribute->new( name => '$constructor', initial_value => \(my $constructor)     ) );
    $::Class->add_attribute( $::Attribute->new( name => '$destructor',  initial_value => \(my $destructor)      ) );


    # create Role here ...

    $::Role->add_method( $::Method->new( name => 'attribute_class',   body => sub { $::Attribute } ) );
    $::Role->add_method( $::Method->new( name => 'method_class',      body => sub { $::Method    } ) );

    $::Role->add_attribute( $::Attribute->new( name => '$name',        initial_value => \(my $role_name)      ) );
    $::Role->add_attribute( $::Attribute->new( name => '$version',     initial_value => \(my $role_version)   ) );
    $::Role->add_attribute( $::Attribute->new( name => '$authority',   initial_value => \(my $role_authority) ) );
    $::Role->add_attribute( $::Attribute->new( name => '$attributes',  initial_value => \sub { +{} }          ) );
    $::Role->add_attribute( $::Attribute->new( name => '$methods',     initial_value => \sub { +{} }          ) );

    $::Role->add_method( $::Method->new( name => 'get_name',           body => $reader->( '$name' )       ) );
    $::Role->add_method( $::Method->new( name => 'get_version',        body => $reader->( '$version' )    ) );
    $::Role->add_method( $::Method->new( name => 'get_authority',      body => $reader->( '$authority' )  ) );
    $::Role->add_method( $::Method->new( name => 'get_all_attributes', body => $reader->( '$attributes' ) ) );
    $::Role->add_method( $::Method->new( name => 'get_all_methods',    body => $reader->( '$methods'    ) ) );

    $::Role->add_method( $::Method->new( name => 'set_version', body => $writer->( '$version' ) ) );

    $::Role->add_method( $::Method->new( name => 'find_attribute', body => sub { $::SELF->get_all_attributes->{ $_[0] } } ) );
    $::Role->add_method( $::Method->new( name => 'find_method',    body => sub { $::SELF->get_all_methods->{ $_[0] } }    ) );

    $::Role->set_constructor( $::Method->new(
        name => 'BUILD',
        body => sub {
            my $v = $::SELF->get_version;
            $::SELF->set_version(version->parse($v))
                if defined $v;
        },
    ) );

    ## TODO NOTES:
    # so if we were to leave out the marked class attributes
    # and methods and then once we reach this spot, compose
    # Role into Class, then the result would be:
    #    - Class does Role
    #    - Role isa Class
    #    - therefore Role does Role
    # in order to accomplish this the composition logic
    # needs to live in Role, but will be merged into Class
    # at which point Class can do it too.

    # Role needs two methods for composition:
    #   - compose( Role $role )
    #   - merge( Array[Roles] @roles )
    # because compose will expect something that
    # does Role, and Class does Role, the method
    # should work polymophically.

    ## --------------------------------
    ## UNIVERSAL methods
    ## --------------------------------

    # implement all of UNIVERSAL here, because the mop's dispatcher should
    # not be using UNIVERSAL at all

    $::Object->add_method( $::Method->new( name => 'isa',  body => sub { ref( $_[0] ) && ( $::CLASS->equals( $_[0] ) || $::CLASS->is_subclass_of( $_[0] ) ) } ) );
    # XXX ideally, ->can would return a method object, which would do the
    # right thing when used as a coderef (so that
    # if (my $foo = $obj->can('foo')) { $obj->$foo(...) }
    # and similar things work as expected), but as far as i can tell,
    # overloading doesn't currently work with anonymous packages
    $::Object->add_method( $::Method->new( name => 'can',  body => sub { my $m = $::CLASS->find_method( $_[0] ); $m ? sub { $m->execute( @_ ) } : () } ) );
    $::Object->add_method( $::Method->new( name => 'DOES',  body => sub { $::SELF->isa( @_ ) } ) );

    # VERSION is really a class method
    # XXX this logic is not nearly right, it should really use the logic
    # used by the current UNIVERSAL::VERSION, but UNIVERSAL::VERSION looks
    # up the class's version in $VERSION, which isn't what we want
    $::Class->add_method( $::Method->new(
        name => 'VERSION',
        body => sub {
            my $ver = $::SELF->get_version;

            if ( @_ ) {
                die "Invalid version format (non-numeric data)"
                    unless version::is_lax( $_[0] );

                my $req = version->parse( $_[0] );

                if ( $ver < $req ) {
                    die sprintf ("%s version %s required--".
                            "this is only version %s", $::SELF->get_name,
                            $req->stringify, $ver->stringify);
                }
            }

            return $ver;
        }
    ) );


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
        $::SELF->get_local_methods->{ $method->get_name } = $method;
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
metacircularity. Additionally, in order to get the right role
features we also create the following relationship:

  Role is an instance of Class
  Class consumes Role
  (therefore) Role does Role

=head1 BOOTSTRAP GOAL

Below is an illustration of goal of the bootstrapping process
defined in the p5-mop syntax itself. This is purely for
illustrative purposes and it not meant to be executable.

  class Role (metaclass => Class) {
      has $name;
      has $version;
      has $authority;
      has $attributes   = {};
      has $methods      = {};
      has $roles        = [];

      method attribute_class      ()           { ... }
      method method_class         ()           { ... }

      method get_name             ()           { ... }
      method get_version          ()           { ... }
      method get_authority        ()           { ... }

      method find_attribute       ($name)      { ... }
      method get_all_attributes   ()           { ... }
      method find_method          ($name)      { ... }
      method get_all_methods      ()           { ... }

      method add_method           ($method)    { ... }
      method add_attribute        ($attribute) { ... }

      method set_version          ($version)   { ... }

      method does_role            ($role)      { ... }

      method COMPOSE              ($role)      { ... }
  }

  class Class (extends => Object, with => Role, metaclass => Class) {

      has $superclass;
      has $constructor;
      has $destructor;

      BUILD {
          # set default base object
          # coerce $version to a version object
          # metaclass compatibility checking
          ...
      }

      method get_superclass       ()           { ... }
      method get_local_attributes ()           { ... }
      method get_local_methods    ()           { ... }
      method get_constructor      ()           { ... }
      method get_destructor       ()           { ... }
      method base_object_class    ()           { ... }

      method equals               ($class)     { ... }
      method get_compatible_class ($class)     { ... }
      method get_dispatcher       ($type)      { ... }
      method get_mro              ()           { ... }
      method is_subclass_of       ($class)     { ... }

      method set_superclass       ($class)     { ... }
      method set_constructor      ($method)    { ... }
      method set_destructor       ($method)    { ... }

      method create_instance      ($params)    { ... }
      method new                  (%params)    { ... }

      method FINALIZE             ()           { ... }

      method VERSION              ()           { ... }
  }

  class Object (metaclass => Class) {
      method isa  ($class) { ... }
      method can  ($name)  { ... }
      method DOES ($class) { ... }
  }

  class Method (extends => Object, metaclass => Class) {
      has $name;
      has $body;

      method get_name ()        { ... }
      method get_body ()        { ... }

      method clone    (%params) { ... }

      method execute  (@args)   { ... }
  }

  class Attribute (extends => Object, metaclass => Class) {
      has $name;
      has $initial_value;

      method get_name                       ()        { ... }
      method get_initial_value              ()        { ... }

      method get_initial_value_for_instance ()        { ... }
      method get_param_name                 ()        { ... }

      method clone                          (%params) { ... }
  }

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
