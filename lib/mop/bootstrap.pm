package mop::bootstrap;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use version ();

use mop::internal;
use mop::internal::instance qw(get_slot_at set_slot_at get_class set_class);
use mop::internal::stashes qw(get_stash_for apply_overloading_for_stash);

# declare some subs so that the rest of the file can be parsed without
# requiring parentheses on class names
package mop::bootstrap::mini {
    sub HasMethods ();
    sub HasAttributes ();
    sub HasRoles ();
    sub HasName ();
    sub HasVersion ();
    sub HasSuperclass ();
    sub Instantiable ();
    sub Dispatchable ();
    sub Cloneable ();
    sub Role ();
    sub Object ();
    sub Class ();
    sub Method ();
    sub Attribute ();
}

package mop::bootstrap::full {
    sub HasMethods ();
    sub HasAttributes ();
    sub HasRoles ();
    sub HasName ();
    sub HasVersion ();
    sub HasSuperclass ();
    sub Instantiable ();
    sub Dispatchable ();
    sub Cloneable ();
    sub Role ();
    sub Object ();
    sub Class ();
    sub Method ();
    sub Attribute ();
}

sub init {
    # =======
    # Phase 0
    # =======
    # Check to see if we want to populate the mop via a serialized form
    # instead.
    if (-e 'lib/mop/bootstrap.mop') {
        deserialize();
        return;
    }

    # =======
    # Phase 1
    # =======
    # First, use mop::mini to create the mop classes. mop::mini uses the same
    # parser as the full mop, but creates normal perl stash-based classes
    # instead (so they don't require any special setup). This creates a class
    # structure which is capable of creating new full mop objects, but is
    # implemented in terms of the mini mop (so mop::class_of(Class) is
    # mop::mini::class). The mini mop doesn't use any metaobjects, so it
    # doesn't matter that $::Class and such aren't populated yet.
    package mop::bootstrap::mini {
        require mop::mini::syntax;
        mop::mini::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';
    }

    # =========
    # Phase 1.5
    # =========
    # Now that we have a mop capable of creating fully functional objects, we
    # need to do some preparation before we can use those objects to create the
    # full mop. First, we populate the necessary globals (since in the full
    # mop, the 'class' keyword is implemented via $::Class->new), and then we
    # clear the %INC cache for the bootstrap so that calling require will
    # evaluate the code again.
    $::Class     = mop::bootstrap::mini::Class;
    $::Role      = mop::bootstrap::mini::Role;
    $::Method    = mop::bootstrap::mini::Method;
    $::Attribute = mop::bootstrap::mini::Attribute;

    delete $INC{'mop/bootstrap.pl'};

    # =======
    # Phase 2
    # =======
    # Now we can use the classes we just created to recreate the mop using full
    # mop objects. This means that class_of(Class) will also be a full mop
    # object (although it won't yet be Class - it'll be the Class object we
    # created in phase 1). The point here is that the metaobjects are now
    # structurally the same, so we can just swap things around in order to tie
    # the knot.
    package mop::bootstrap::full {
        require mop::syntax;
        mop::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';
    }

    # =======
    # Phase 3
    # =======
    # Now, populate all of the globals with the objects that we just built, so
    # they can be used. Also, collect them all in an array so we can use them
    # later.
    my @metaobjects = (
        ($::Object        = mop::bootstrap::full::Object       ),
        ($::Class         = mop::bootstrap::full::Class        ),
        ($::Role          = mop::bootstrap::full::Role         ),
        ($::Method        = mop::bootstrap::full::Method       ),
        ($::Attribute     = mop::bootstrap::full::Attribute    ),
        ($::HasMethods    = mop::bootstrap::full::HasMethods   ),
        ($::HasAttributes = mop::bootstrap::full::HasAttributes),
        ($::HasRoles      = mop::bootstrap::full::HasRoles     ),
        ($::HasName       = mop::bootstrap::full::HasName      ),
        ($::HasVersion    = mop::bootstrap::full::HasVersion   ),
        ($::HasSuperclass = mop::bootstrap::full::HasSuperclass),
        ($::Instantiable  = mop::bootstrap::full::Instantiable ),
        ($::Dispatchable  = mop::bootstrap::full::Dispatchable ),
        ($::Cloneable     = mop::bootstrap::full::Cloneable    ),
    );

    # =======
    # Phase 4
    # =======
    # Now that the classes are all created, and their metaclasses are all full
    # mop objects, we can swap out the metaclasses that currently exist for the
    # corresponding ones in the full mop, which ties the knot (sets up the
    # metacircularity).
    my $class_stash     = get_stash_for($::Class);
    my $role_stash      = get_stash_for($::Role);
    my $method_stash    = get_stash_for($::Method);
    my $attribute_stash = get_stash_for($::Attribute);

    for my $class (@metaobjects) {
        if (get_class($class) == mop::bootstrap::mini::Class) {
            set_class($class, $::Class);
            $class_stash->bless($class);

            if (my $constructor = ${ get_slot_at($class, '$constructor') }) {
                set_class($constructor, $::Method);
                $method_stash->bless($constructor);
            }

            if (my $destructor = ${ get_slot_at($class, '$destructor') }) {
                set_class($destructor, $::Method);
                $method_stash->bless($destructor);
            }
        }
        else {
            set_class($class, $::Role);
            $role_stash->bless($class);
        }

        for my $attribute (values %{ get_slot_at($class, '%attributes') }) {
            set_class($attribute, $::Attribute);
            $attribute_stash->bless($attribute);
        }

        for my $method (values %{ get_slot_at($class, '%methods') }) {
            set_class($method, $::Method);
            $method_stash->bless($method);
        }
    }

    # =======
    # Phase 5
    # =======
    # Fill in some metadata that we didn't do earlier - we could have defined
    # this in the bootstrap directly, but it would have just been kind of
    # repetitive and ugly, so easier to read to do it here.
    for my $class (@metaobjects) {
        set_slot_at($class, '$version',   \version->parse($mop::VERSION));
        set_slot_at($class, '$authority', \$mop::AUTHORITY);
        set_slot_at($class, '$name',
                    \(${ get_slot_at($class, '$name') } =~ s/.*:://r));
    }

    # =======
    # Phase 6
    # =======
    # Now we reconstruct the stashes for the objects, since the existing
    # stashes are populated with methods that refer to the method objects from
    # phase 1. This is basically copied from $::Class->FINALIZE, but we need to
    # avoid calling methods on the metaobjects until everything is completely
    # in place or else things don't work properly.
    for my $class (@metaobjects) {
        next unless get_class($class) == $::Class;

        my $stash = get_stash_for($class);
        my %methods = (
            (map { %{ get_slot_at($_, '%methods') } }
                 (${ get_slot_at($class, '$superclass') } || ()),
                 @{ get_slot_at($class, '@roles') },
                 $class),
        );

        %$stash = ();

        for my $name (keys %methods) {
            my $method = $methods{$name};
            $stash->add_method($name => sub { $method->execute(@_) });
        }
        $stash->add_method(
            DESTROY => mop::internal::stashes::generate_DESTROY()
        );

        apply_overloading_for_stash($stash);
    }

    # Break the cycle with Method->execute, since we just regenerated its stash
    # entry to call itself recursively.
    get_stash_for($::Method)->add_method(execute => sub {
        mop::internal::execute_method(@_)
    });

    # =======
    # Phase 7
    # =======
    # There were a couple things in the bootstrap that can't be defined in
    # there directly, or require a different implementation while bootstrapping
    # than for actual use. These get fixed up or replaced or whatever at this
    # point.
    fixup_after_bootstrap();

    # And we're done!
    return;
}

sub deserialize {
    # =======
    # Phase 1
    # =======
    # First, load the raw data structures themselves from disk. This doesn't
    # include any of the methods or attribute defaults, since perl can't
    # serialize those reliably. We'll fill those in later.
    require Storable;
    my $mop = Storable::retrieve('lib/mop/bootstrap.mop');

    # =======
    # Phase 2
    # =======
    # Populate the globals from the data we loaded, and stick them in an array
    # so we can use them below.
    my @metaobjects = (
        ($::Object        = $mop->{Object}       ),
        ($::Class         = $mop->{Class}        ),
        ($::Role          = $mop->{Role}         ),
        ($::Method        = $mop->{Method}       ),
        ($::Attribute     = $mop->{Attribute}    ),
        ($::HasMethods    = $mop->{HasMethods}   ),
        ($::HasAttributes = $mop->{HasAttributes}),
        ($::HasRoles      = $mop->{HasRoles}     ),
        ($::HasName       = $mop->{HasName}      ),
        ($::HasVersion    = $mop->{HasVersion}   ),
        ($::HasSuperclass = $mop->{HasSuperclass}),
        ($::Instantiable  = $mop->{Instantiable} ),
        ($::Dispatchable  = $mop->{Dispatchable} ),
        ($::Cloneable     = $mop->{Cloneable}    ),
    );

    # =======
    # Phase 3
    # =======
    # Now parse the bootstrap code. The only purpose here is to find the bits
    # of it which couldn't be serialized (just coderefs at this point) and fill
    # them in. For instance, when it reaches a method definition, it just takes
    # the body coderef and sets the method body to that coderef - it doesn't
    # create new method objects or anything like that. This also recreates the
    # stashes, since they can't be serialized.
    package mop::bootstrap::full {
        require mop::deserialize::syntax;
        mop::deserialize::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';
    }

    # Break the cycle with Method->execute, since we just regenerated its stash
    # entry to call itself recursively.
    get_stash_for($::Method)->add_method(execute => sub {
        mop::internal::execute_method(@_)
    });

    # =======
    # Phase 4
    # =======
    # Now go through and rebless everything into the proper stashes.
    my $class_stash     = get_stash_for($::Class);
    my $role_stash      = get_stash_for($::Role);
    my $method_stash    = get_stash_for($::Method);
    my $attribute_stash = get_stash_for($::Attribute);

    for my $class (@metaobjects) {
        if (get_class($class) == $::Class) {
            $class_stash->bless($class);

            if (my $constructor = ${ get_slot_at($class, '$constructor') }) {
                $method_stash->bless($constructor);
            }
            if (my $destructor = ${ get_slot_at($class, '$destructor') }) {
                $method_stash->bless($destructor);
            }
        }
        else {
            $role_stash->bless($class);
        }

        for my $method (values %{ get_slot_at($class, '%methods') }) {
            $method_stash->bless($method);
        }
        for my $attr (values %{ get_slot_at($class, '%attributes') }) {
            $attribute_stash->bless($attr);
        }
    }

    # =======
    # Phase 5
    # =======
    # Since parsing the bootstrap code only populates methods and attribute
    # defaults into the role or class they were originally defined in, if they
    # were defined in a role, we need to copy those coderefs around into all of
    # the classes that consume that role.
    for my $class (@metaobjects) {
        next unless get_class($class) == $::Class;

        my %class_methods = %{ get_slot_at($class, '%methods') };
        my %class_attrs = %{ get_slot_at($class, '%attributes') };

        for my $role (@{ get_slot_at($class, '@roles') }) {
            for my $method (values %{ get_slot_at($role, '%methods') }) {
                my $name = ${ get_slot_at($method, '$name') };
                # XXX need to track sources - these are role methods which are
                # overridden in $::Class
                if ($class == $::Class) {
                    next if $name eq 'methods'
                        || $name eq 'attributes'
                        || $name eq 'roles'
                        || $name eq 'instance_DOES';
                }
                my $body = ${ get_slot_at($method, '$body') };
                set_slot_at($class_methods{$name}, '$body', \$body);
            }
            for my $attr (values %{ get_slot_at($role, '%attributes') }) {
                my $name = ${ get_slot_at($attr, '$name') };
                my $default = ${ get_slot_at($attr, '$initial_value') };
                set_slot_at($class_attrs{$name}, '$initial_value', \$default);
            }
        }
    }

    # =======
    # Phase 6
    # =======
    # And, since we populated the coderefs from parsing the bootstrap code, we
    # still need to replace the implementations of things that need alternate
    # implementations here too, just like in the non-serialized codepath.
    fixup_after_bootstrap();

    # And we're done!
    return;
}

# replace some methods that we hardcoded in the initial mop with some working
# variants that actually use the full mop instead of the mini mop
sub fixup_after_bootstrap {
    # ================
    # Cloneable->clone
    # ================
    {
        # create the method
        my $clone = sub {
            my %params = (
                (map {
                    $_->param_name => ($_->sigil eq '$'
                        ? ${ get_slot_at($::SELF, $_->name) }
                        : get_slot_at($::SELF, $_->name))
                } values %{ $::CLASS->attributes }),
                @_,
            );
            return $::CLASS->new(%params);
        };

        my $method = $::Method->new(
            name => 'clone',
            body => $clone,
        );

        # add it to its initial role
        $::Cloneable->add_method($method);

        # clone it into each of the classes that consume Cloneable
        # note that we can't call $method->clone yet, since that's what we're
        # trying to define
        local $::SELF = $method;
        local $::CLASS = $::Method;
        $::Role->add_method($clone->());
        $::Class->add_method($clone->());
        $::Method->add_method($clone->());
        $::Attribute->add_method($clone->());
    }
    # and now fix up the stashes of all of the classes that consume Cloneable
    for my $cloneable ($::Role, $::Class, $::Method, $::Attribute) {
        my $method = ${ get_slot_at($cloneable, '%methods') }{clone};
        get_stash_for($cloneable)->add_method(clone => sub {
            $method->execute(@_)
        });
    }

    # ============
    # Class->BUILD
    # ============
    $::Class->set_constructor($::Method->new(
        name => 'BUILD',
        body => sub {
            $::SELF->set_superclass($::SELF->base_object_class)
                unless $::SELF->superclass;

            my $v = $::SELF->version;
            $::SELF->set_version(version->parse($v))
                if defined $v;

            my $superclass = $::SELF->superclass;
            if ($superclass) {
                my $superclass_class = get_class($superclass);
                my $compatible = $::CLASS->find_compatible_class($superclass_class);
                if (!defined($compatible)) {
                    die "While creating class " . $::SELF->name . ": "
                    . "Metaclass " . $::CLASS->name . " is not compatible "
                    . "with the metaclass of its superclass: "
                    . $superclass_class->name;
                }
            }
        },
    ));
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

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
