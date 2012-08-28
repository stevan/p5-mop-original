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
    }

    delete $INC{'mop/bootstrap.pl'};

    {
        package mop::bootstrap::full;
        require mop::syntax;
        mop::syntax->setup_for(__PACKAGE__);

        *HasMethods    = \&mop::bootstrap::mini::HasMethods;
        *HasAttributes = \&mop::bootstrap::mini::HasAttributes;
        *HasRoles      = \&mop::bootstrap::mini::HasRoles;
        *HasName       = \&mop::bootstrap::mini::HasName;
        *HasVersion    = \&mop::bootstrap::mini::HasVersion;
        *HasSuperclass = \&mop::bootstrap::mini::HasSuperclass;
        *Instantiable  = \&mop::bootstrap::mini::Instantiable;
        *Dispatchable  = \&mop::bootstrap::mini::Dispatchable;
        *Cloneable     = \&mop::bootstrap::mini::Cloneable;
        *Role          = \&mop::bootstrap::mini::Role;
        *Object        = \&mop::bootstrap::mini::Object;
        *Class         = \&mop::bootstrap::mini::Class;
        *Method        = \&mop::bootstrap::mini::Method;
        *Attribute     = \&mop::bootstrap::mini::Attribute;

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

    for my $role (@roles) {
        mop::internal::instance::set_class($role, $::Role);
        mop::internal::get_stash_for($::Role)->bless($role);

        mop::internal::instance::set_slot_at($role, '$version', \$mop::VERSION);
        mop::internal::instance::set_slot_at($role, '$authority', \$mop::AUTHORITY);
        mop::internal::instance::set_slot_at($role, '$name', \($role->get_name =~ s/.*:://r));

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
        if ($class->get_superclass) {
            mop::internal::instance::set_slot_at($class, '$superclass', \$::Object);
        }
        mop::internal::get_stash_for($::Class)->bless($class);
        mop::internal::instance::set_slot_at($class, '$version', \$mop::VERSION);
        mop::internal::instance::set_slot_at($class, '$authority', \$mop::AUTHORITY);
        mop::internal::instance::set_slot_at($class, '$name', \($class->get_name =~ s/.*:://r));

        for my $attribute (values %{ mop::internal::instance::get_slot_at($class, '$attributes') }) {
            mop::internal::instance::set_class($attribute, $::Attribute);
            mop::internal::get_stash_for($::Attribute)->bless($attribute);
        }

        for my $method (values %{ mop::internal::instance::get_slot_at($class, '$methods') }) {
            mop::internal::instance::set_class($method, $::Method);
            mop::internal::get_stash_for($::Method)->bless($method);
        }
    }

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

=head1 BOOTSTRAP GOAL

Below is an illustration of goal of the bootstrapping process
defined in the pr-5mop syntax itself. This is purely for
illustrative purposes and it not meant to be executable.

  role HasMethods (metaclass => Role) {
      has $methods      = {};

      method get_local_methods    ()           { ... }

      method method_class         ()           { ... }

      method find_method          ($name)      { ... }
      method get_all_methods      ()           { ... }

      method add_method           ($method)    { ... }
  }

  role HasAttributes (metaclass => Role) {
      has $attributes   = {};

      method get_local_attributes ()           { ... }

      method attribute_class      ()           { ... }

      method find_attribute       ($name)      { ... }
      method get_all_attributes   ()           { ... }

      method add_attribute        ($attribute) { ... }
  }

  role HasRoles (metaclass => Role) {
      has $roles = [];

      method get_local_roles      ()           { ... }
      method get_all_roles        ()           { ... }
  }

  role HasName (metaclass => Role) {
      has $name;

      method get_name             ()           { ... }
  }

  role HasVersion (metaclass => Role) {
      has $version;
      has $authority;

      BUILD {
          # coerce $version to a version object
          ...
      }

      method get_version          ()           { ... }
      method get_authority        ()           { ... }

      method set_version          ($version)   { ... }

      method VERSION              ()           { ... }
  }

  # XXX handwavy
  role HasRequiredMethods (metaclass => Role) {
      has $required_methods = {};
  }

  # XXX handwavy
  role Composable (metaclass => Role) {
      method apply                ()           { ... }
  }

  role HasSuperclass (metaclass => Role) {
      has $superclass;

      BUILD {
          # set default base object
          # metaclass compatibility checking
          ...
      }

      method get_superclass       ()           { ... }

      method base_object_class    ()           { ... }

      method get_compatible_class ($class)     { ... }
      method is_subclass_of       ($class)     { ... }

      method set_superclass       ($class)     { ... }
  }

  role Instantiatable (metaclass => Role) {
      has $constructor;
      has $destructor;

      method get_constructor      ()           { ... }
      method get_destructor       ()           { ... }
      method set_constructor      ($method)    { ... }
      method set_destructor       ($method)    { ... }

      method create_instance      ($params)    { ... }
      method new                  (%params)    { ... }
  }

  role Dispatchable (metaclass => Role) {
      method get_mro              ()           { ... }
      method get_dispatcher       ($type)      { ... }
  }

  role Cloneable (metaclass => Role) {
      method clone                (%params)    { ... }
  }

  class Role (with => [HasMethods, HasAttributes, HasRoles, HasName, HasVersion, HasRequiredMethods, Composable, Cloneable], extends => Object, metaclass => Class) {
      method FINALIZE             ()           { ... }
  }

  class Class (with => [HasMethods, HasAttributes, HasRoles, HasName, HasVersion, HasSuperclasses, Instantiatable, Dispatchable, Cloneable], extends => Object, metaclass => Class) {
      method FINALIZE             ()           { ... }
  }

  class Object (metaclass => Class) {
      method isa  ($class) { ... }
      method can  ($name)  { ... }
      method DOES ($class) { ... }
  }

  class Method (extends => Object, metaclass => Class, with => [Cloneable]) {
      has $name;
      has $body;

      method get_name ()        { ... }
      method get_body ()        { ... }

      method execute  (@args)   { ... }
  }

  class Attribute (extends => Object, metaclass => Class, with => [Cloneable]) {
      has $name;
      has $initial_value;

      method get_name                       ()        { ... }
      method get_initial_value              ()        { ... }

      method get_initial_value_for_instance ()        { ... }
      method get_param_name                 ()        { ... }
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
