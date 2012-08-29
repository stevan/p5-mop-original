package mop::bootstrap;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Scalar::Util ();
use version ();

use mop::internal;

{
    package mop::bootstrap::mini;

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

{
    package mop::bootstrap::full;

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
    {
        package mop::bootstrap::mini;
        require mop::mini::syntax;
        mop::mini::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';

        $::Object    = Object;
        $::Class     = Class;
        $::Role      = Role;
        $::Method    = Method;
        $::Attribute = Attribute;

        $::HasMethods    = HasMethods;
        $::HasAttributes = HasAttributes;
        $::HasRoles      = HasRoles;
        $::HasName       = HasName;
        $::HasVersion    = HasVersion;
        $::HasSuperclass = HasSuperclass;
        $::Instantiable  = Instantiable;
        $::Dispatchable  = Dispatchable;
        $::Cloneable     = Cloneable;
    }

    delete $INC{'mop/bootstrap.pl'};

    {
        package mop::bootstrap::full;
        require mop::syntax;
        mop::syntax->setup_for(__PACKAGE__);

        require 'mop/bootstrap.pl';

        $::Object    = Object;
        $::Class     = Class;
        $::Role      = Role;
        $::Method    = Method;
        $::Attribute = Attribute;

        $::HasMethods    = HasMethods;
        $::HasAttributes = HasAttributes;
        $::HasRoles      = HasRoles;
        $::HasName       = HasName;
        $::HasVersion    = HasVersion;
        $::HasSuperclass = HasSuperclass;
        $::Instantiable  = Instantiable;
        $::Dispatchable  = Dispatchable;
        $::Cloneable     = Cloneable;
    }

    my @classes = (
        $::Object,
        $::Class,
        $::Role,
        $::Method,
        $::Attribute,
    );
    my @roles = (
        $::HasMethods,
        $::HasAttributes,
        $::HasRoles,
        $::HasName,
        $::HasVersion,
        $::HasSuperclass,
        $::Instantiable,
        $::Dispatchable,
        $::Cloneable,
    );

    # fix up the objects, which are still mini-mop objects at this point
    for my $role (@roles) {
        mop::internal::instance::set_class($role, $::Role);
        mop::internal::get_stash_for($::Role)->bless($role);

        mop::internal::instance::set_slot_at($role, '$version', \$mop::VERSION);
        mop::internal::instance::set_slot_at($role, '$authority', \$mop::AUTHORITY);
        mop::internal::instance::set_slot_at($role, '$name', \(mop::internal::instance::get_slot_at($role, '$name') =~ s/.*:://r));

        for my $attribute (values %{ mop::internal::instance::get_slot_at($role, '$attributes') }) {
            mop::internal::instance::set_class($attribute, $::Attribute);
            mop::internal::get_stash_for($::Attribute)->bless($attribute);
        }

        for my $method (values %{ mop::internal::instance::get_slot_at($role, '$methods') }) {
            mop::internal::instance::set_class($method, $::Method);
            mop::internal::get_stash_for($::Method)->bless($method);
        }
    }
    for my $class (@classes) {
        mop::internal::instance::set_class($class, $::Class);
        mop::internal::get_stash_for($::Class)->bless($class);
        mop::internal::instance::set_slot_at($class, '$version', \$mop::VERSION);
        mop::internal::instance::set_slot_at($class, '$authority', \$mop::AUTHORITY);
        mop::internal::instance::set_slot_at($class, '$name', \(mop::internal::instance::get_slot_at($class, '$name') =~ s/.*:://r));

        for my $attribute (values %{ mop::internal::instance::get_slot_at($class, '$attributes') }) {
            mop::internal::instance::set_class($attribute, $::Attribute);
            mop::internal::get_stash_for($::Attribute)->bless($attribute);
        }

        for my $method (values %{ mop::internal::instance::get_slot_at($class, '$methods') }) {
            mop::internal::instance::set_class($method, $::Method);
            mop::internal::get_stash_for($::Method)->bless($method);
        }
    }

    # now reconstruct the stashes
    for my $class (@classes) {
        my $stash = mop::internal::get_stash_for($class);
        my $methods = {
            (map { %{ mop::internal::instance::get_slot_at($_, '$methods') } }
                (mop::internal::instance::get_slot_at($class, '$superclass') || ()),
                @{ mop::internal::instance::get_slot_at($class, '$roles') }),
            %{ mop::internal::instance::get_slot_at($class, '$methods') },
        };
        %$stash = ();
        for my $name (keys %$methods) {
            my $method = $methods->{$name};
            $stash->add_method($name => sub { $method->execute(@_) });
        }
    }

    # break the cycle with Method->execute, since we just regenerated its stash
    # entry to call itself recursively
    mop::internal::get_stash_for($::Method)->add_method(execute => sub {
        mop::internal::execute_method(@_)
    });

    # and replace some methods that we hardcoded in the initial mop, with some
    # better variants that actually use the full mop
    {
        my $clone = sub {
            my %params = (
                (map {
                    $_->get_param_name => mop::internal::instance::get_slot_at(
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
    {
        my $method = mop::internal::instance::get_slot_at($::Role, '$methods')->{clone};
        mop::internal::get_stash_for($::Role)->add_method(clone => sub {
            $method->execute(@_)
        });
    }
    {
        my $method = mop::internal::instance::get_slot_at($::Class, '$methods')->{clone};
        mop::internal::get_stash_for($::Class)->add_method(clone => sub {
            $method->execute(@_)
        });
    }
    {
        my $method = mop::internal::instance::get_slot_at($::Method, '$methods')->{clone};
        mop::internal::get_stash_for($::Method)->add_method(clone => sub {
            $method->execute(@_)
        });
    }
    {
        my $method = mop::internal::instance::get_slot_at($::Attribute, '$methods')->{clone};
        mop::internal::get_stash_for($::Attribute)->add_method(clone => sub {
            $method->execute(@_)
        });
    }

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
