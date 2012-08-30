package mop::bootstrap;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();
use version ();

use mop::internal;
use mop::internal::instance;

package mop::bootstrap::mini {
    sub HasMethods;
    sub HasAttributes;
    sub HasRoles;
    sub HasName;
    sub HasVersion;
    sub HasSuperclass;
    sub Instantiable;
    sub Dispatchable;
    sub Cloneable;
    sub Role;
    sub Object;
    sub Class;
    sub Method;
    sub Attribute;
}

package mop::bootstrap::full {
    sub HasMethods;
    sub HasAttributes;
    sub HasRoles;
    sub HasName;
    sub HasVersion;
    sub HasSuperclass;
    sub Instantiable;
    sub Dispatchable;
    sub Cloneable;
    sub Role;
    sub Object;
    sub Class;
    sub Method;
    sub Attribute;
}

sub init {
    package mop::bootstrap::mini {
        require mop::mini::syntax;
        mop::mini::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';
    }

    delete $INC{'mop/bootstrap.pl'};

    $::Class     = mop::bootstrap::mini::Class;
    $::Role      = mop::bootstrap::mini::Role;
    $::Method    = mop::bootstrap::mini::Method;
    $::Attribute = mop::bootstrap::mini::Attribute;

    package mop::bootstrap::full {
        require mop::syntax;
        mop::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';
    }

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

    my @classes = grep {
        get_class($_) == mop::bootstrap::mini::Class
    } @metaobjects;
    my @roles   = grep {
        get_class($_) == mop::bootstrap::mini::Role
    } @metaobjects;

    # fix up the objects, which are still mini-mop objects at this point
    # this section intentionally doesn't call any methods, to avoid needing
    # to use the mop when it's in a halfway transition state
    for my $role (@roles) {
        set_class($role, $::Role);
        get_stash_for($::Role)->bless($role);

        set_slot_at($role, '$version', \$mop::VERSION);
        set_slot_at($role, '$authority', \$mop::AUTHORITY);
        set_slot_at($role, '$name', \(get_slot_at($role, '$name') =~ s/.*:://r));

        for my $attribute (values %{ get_slot_at($role, '$attributes') }) {
            set_class($attribute, $::Attribute);
            get_stash_for($::Attribute)->bless($attribute);
        }

        for my $method (values %{ get_slot_at($role, '$methods') }) {
            set_class($method, $::Method);
            get_stash_for($::Method)->bless($method);
        }
    }

    for my $class (@classes) {
        set_class($class, $::Class);
        get_stash_for($::Class)->bless($class);

        set_slot_at($class, '$version', \$mop::VERSION);
        set_slot_at($class, '$authority', \$mop::AUTHORITY);
        set_slot_at($class, '$name', \(get_slot_at($class, '$name') =~ s/.*:://r));

        for my $attribute (values %{ get_slot_at($class, '$attributes') }) {
            set_class($attribute, $::Attribute);
            get_stash_for($::Attribute)->bless($attribute);
        }

        for my $method (values %{ get_slot_at($class, '$methods') }) {
            set_class($method, $::Method);
            get_stash_for($::Method)->bless($method);
        }
    }

    # now reconstruct the stashes (not using FINALIZE or _generate_callable_sub
    # because we're still avoiding method calls)
    for my $class (@classes) {
        my $stash = get_stash_for($class);
        my $methods = {
            (map { %{ get_slot_at($_, '$methods') } }
                (get_slot_at($class, '$superclass') || ()),
                @{ get_slot_at($class, '$roles') },
                $class),
        };
        %$stash = ();
        for my $name (keys %$methods) {
            my $method = $methods->{$name};
            $stash->add_method($name => sub { $method->execute(@_) });
        }
        # XXX DESTROY?
    }

    # break the cycle with Method->execute, since we just regenerated its stash
    # entry to call itself recursively
    get_stash_for($::Method)->add_method(execute => sub {
        mop::internal::execute_method(@_)
    });

    # and replace some methods that we hardcoded in the initial mop, with some
    # working variants that actually use the full mop instead of the mini mop
    {
        my $clone = sub {
            my %params = (
                (map {
                    $_->get_param_name => get_slot_at(
                        $::SELF, $_->get_name
                    )
                } values %{ $::CLASS->get_all_attributes }),
                @_,
            );
            return $::CLASS->new(%params);
        };

        my $method = $::Method->new(
            name => 'clone',
            body => $clone,
        );

        $::Cloneable->add_method($method);

        local $::SELF = $method;
        local $::CLASS = $::Method;
        $::Role->add_method($clone->());
        $::Class->add_method($clone->());
        $::Method->add_method($clone->());
        $::Attribute->add_method($clone->());
    }
    for my $cloneable ($::Role, $::Class, $::Method, $::Attribute) {
        my $method = get_slot_at($cloneable, '$methods')->{clone};
        get_stash_for($cloneable)->add_method(clone => sub {
            $method->execute(@_)
        });
    }

    # and finally, install the constructor for classes
    $::Class->set_constructor($::Method->new(
        name => 'BUILD',
        body => sub {
            $::SELF->set_superclass($::SELF->base_object_class)
                unless $::SELF->get_superclass;

            my $v = $::SELF->get_version;
            $::SELF->set_version(version->parse($v))
                if defined $v;

            my $superclass = $::SELF->get_superclass;
            if ($superclass) {
                my $superclass_class = mop::class_of($superclass);
                my $compatible = $::CLASS->get_compatible_class($superclass_class);
                if (!defined($compatible)) {
                    die "While creating class " . $::SELF->get_name . ": "
                    . "Metaclass " . $::CLASS->get_name . " is not compatible "
                    . "with the metaclass of its superclass: "
                    . $superclass_class->get_name;
                }
            }
        },
    ));

    return;
}

sub get_slot_at   { mop::internal::instance::get_slot_at(@_) }
sub set_slot_at   { mop::internal::instance::set_slot_at(@_) }
sub get_class     { mop::internal::instance::get_class(@_)   }
sub set_class     { mop::internal::instance::set_class(@_)   }
sub get_stash_for { mop::internal::get_stash_for(@_)         }

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
