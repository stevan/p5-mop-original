use strict;
use warnings;
use 5.014;

# implement all of UNIVERSAL here, because the mop's dispatcher should
# not be using UNIVERSAL at all
class Object {
    method isa ($other)  { $class->instance_isa($other) }
    method does ($other) { $class->instance_does($other) }
    method can ($name)   { $class->instance_can($name) }
    method DOES ($other) { $class->instance_DOES($other) }
}

role Cloneable {
    # NOTE: the bootstrap needs to use this, so this implementation needs to
    # handle mini-mop objects. after the bootstrap is done, this is replaced
    # with a real implementation using full mop objects.
    method clone (%params) {
        my $new_instance = mop::internal::instance::create(
            \mop::internal::instance::get_class($self),
            {
                %{ mop::internal::instance::get_slots($self) },
                %params,
            }
        );
        mop::internal::instance::get_class($self)->bless($new_instance);
        return $new_instance;
    }
}

role HasName {
    has $name;

    method name { $name }
}

class Method (extends => Object, roles => [Cloneable, HasName]) {
    has $body;

    method body { $body }

    method is_stub { !defined $body }

    method execute ($invocant, @args) {
        mop::internal::execute_method( $self, $invocant, @args )
    }

    method _generate_callable_sub {
        if ($class == $::Method) {
            return sub { mop::internal::execute_method($self, @_) };
        }
        else {
            return sub { $self->execute(@_) };
        }
    }
}

class Attribute (extends => Object, roles => [Cloneable, HasName]) {
    has $initial_value;

    BUILD {
        my $name = $self->name;
        die "Attribute '$name' has no sigil (did you mean '\$$name'?)"
            unless $name =~ /^[\$\@\%]/;
    }

    method initial_value { $initial_value }

    # XXX this works, but things break if i try to simplify it by returning
    # temporaries - "return \@$value" for instance. not sure why.
    method initial_value_for_instance {
        my $value = $self->initial_value;
        my $sigil = $self->sigil;

        if (ref($value) eq 'REF') {
            if (ref($$value) eq 'CODE') {
                if ($sigil eq '$') {
                    $value = $$value->();
                    return \$value;
                }
                elsif ($sigil eq '@') {
                    my @value = $$value->();
                    return \@value;
                }
                elsif ($sigil eq '%') {
                    my %value = $$value->();
                    return \%value;
                }
                else {
                    die "Unknown sigil $sigil";
                }
            }
            else {
                die "References of type " . ref($value) . " are not supported";
            }
        }
        else {
            if ($sigil eq '$') {
                $value = $$value;
                return \$value;
            }
            elsif ($sigil eq '@') {
                my @value = @$value;
                return \@value;
            }
            elsif ($sigil eq '%') {
                my %value = %$value;
                return \%value;
            }
            else {
                die "Unknown sigil $sigil";
            }
        }
    }

    method prepare_constructor_value_for_instance ($val) { $val }

    method sigil { substr($self->name, 0, 1) }
    method param_name { $self->name =~ s/^[\$\@\%]//r }
}

role HasMethods {
    has %methods;

    method local_methods { \%methods }

    method method_class { $::Method }

    method find_method ($name) {
        $self->methods->{$name};
    }

    method methods {
        $self->local_methods;
    }

    method add_method ($method) {
        $self->local_methods->{$method->name} = $method;
    }

    # XXX ideally, ->can would return a method object, which would do the
    # right thing when used as a coderef (so that
    # if (my $foo = $obj->can('foo')) { $obj->$foo(...) }
    # and similar things work as expected), but as far as i can tell,
    # overloading doesn't currently work with anonymous packages
    method instance_can ($name) {
        my $method = $self->find_method( $name );
        return sub { $method->execute( @_ ) }
            if $method;
        return;
    }
}

role HasAttributes {
    has %attributes;

    method local_attributes { \%attributes }

    method attribute_class { $::Attribute }

    method find_attribute ($name) {
        $self->attributes->{$name};
    }

    method attributes {
        $self->local_attributes;
    }

    method add_attribute ($attribute) {
        $self->local_attributes->{$attribute->name} = $attribute;
    }
}

role HasRoles {
    has @roles;

    method local_roles { @roles }

    method roles_for_composition {
        map { $_, $_->local_roles } $self->local_roles;
    }

    method roles {
        map { $_, $_->local_roles } $self->local_roles;
    }

    method add_roles (@roles_to_add) {
        push @roles, @roles_to_add;
    }

    # XXX very simplistic for now, need a real implementation
    method apply_roles (@roles_to_apply) {
        my $local_methods = $self->local_methods;
        my $local_attributes = $self->local_attributes;

        for my $role (@roles_to_apply) {
            my $methods = $role->local_methods;
            for my $name (keys %$methods) {
                $self->add_method($methods->{$name}->clone)
                    unless exists $local_methods->{$name};
            }
            my $attributes = $role->local_attributes;
            for my $name (keys %$attributes) {
                $self->add_attribute($attributes->{$name}->clone)
                    unless exists $local_attributes->{$name};
            }
        }
    }

    method instance_does ($role) {
        return unless ref($role);
        return !!grep { $_ == $role } $self->roles;
    }
}

# XXX splitting this from HasName probably doesn't make sense, since VERSION
# calls $self->name. maybe we just want a single HasIdentity role?
role HasVersion {
    has $version;
    has $authority;

    # XXX need to figure out what to do about BUILD in roles
    # this logic is in BUILD for Class and Role directly for now
    # BUILD {
        # coerce $version to a version object
        # ...
    # }

    method version   { $version }
    method authority { $authority }

    method set_version ($new_version) { $version = $new_version }

    # XXX this logic is not nearly right, it should really use the logic
    # used by the current UNIVERSAL::VERSION, but UNIVERSAL::VERSION looks
    # up the class's version in $VERSION, which isn't what we want
    method VERSION ($new_version) {
        my $ver = $self->version;

        if ( @_ ) {
            die "Invalid version format (non-numeric data)"
                unless version::is_lax( $new_version );

            my $req = version->parse( $new_version );

            if ( $ver < $req ) {
                die sprintf ("%s version %s required--".
                        "this is only version %s", $self->name,
                        $req->stringify, $ver->stringify);
            }
        }

        return $ver;
    }
}

# and this one calls mro - should probably rethink some of these splits
role HasSuperclass {
    has $superclass;

    # XXX need to figure out what to do about BUILD in roles
    # this logic is in BUILD for Class directly for now
    # BUILD {
        # set default base object
        # metaclass compatibility checking
        # ...
    # }

    method superclass { $superclass }

    method set_superclass ($new) { $superclass = $new }

    method base_object_class { $::Object }

    method find_compatible_class ($other) {
        # it's already okay
        return $self  if $self->instance_isa($other);
        # replace the class with a subclass of itself
        return $other if $other->instance_isa($self);
        # reconciling this group of metaclasses isn't possible
        return;
    }

    method instance_isa ($other) {
        return unless ref($other);
        return !!grep { $other == $_ } @{ $self->mro };
    }
    method instance_DOES ($other) {
        return $self->instance_isa($other);
    }
}

role Instantiable {
    has $constructor;
    has $destructor;

    method constructor { $constructor }
    method destructor  { $destructor }

    method set_constructor ($method) { $constructor = $method }
    method set_destructor  ($method) { $destructor = $method }

    method create_instance ($params) {
        my $data = {};

        my $attrs = $self->attributes;
        foreach my $attr_name ( keys %$attrs ) {
            unless ( exists $data->{ $attr_name } ) {
                my $param_name = $attrs->{ $attr_name }->param_name;
                if ( exists $params->{ $param_name } ) {
                    my $value = $params->{ $param_name };
                    $data->{ $attr_name } = $attrs->{$attr_name}->prepare_constructor_value_for_instance($attrs->{ $attr_name }->sigil eq '$' ? \$value : $value);
                }
                else {
                    $data->{ $attr_name } = $attrs->{$attr_name}->initial_value_for_instance;
                }

            }
        }

        my $stash = mop::internal::get_stash_for( $self );
        die "Could not find stash for class(" . $self->name . ")"
            unless $stash;

        $stash->bless(mop::internal::instance::create( \$self, $data ));
    }

    method BUILDARGS (@params) { +{ @params } }

    method new (@params) {
        my $params = $self->BUILDARGS(@params);
        my $instance = $self->create_instance($params);
        mop::WALKCLASS(
            $self->dispatcher('reverse'),
            sub {
                my $meta = shift;
                my $constructor = $meta->constructor;
                return unless $constructor;
                $constructor->execute($instance, $params);
                return;
            }
        );
        $instance;
    }
}

# XXX this should probably just require mro, not implement it
role Dispatchable {
    method mro {
        # XXX XXX XXX what in the world is this
        # warn "mro for " . $self->name . ' ' . $::SELF->name;
        my $super = $::SELF->superclass;
        # warn $super->name if $super;
        return [ $::SELF, $super ? @{ $super->mro } : () ]
    }

    method dispatcher ($type) {
        return sub { state $mro = $self->mro; shift @$mro }
            unless $type;
        return sub { state $mro = $self->mro; pop   @$mro }
            if $type eq 'reverse';
    }
}

class Role (roles => [HasMethods, HasAttributes, HasRoles, HasName, HasVersion, Cloneable], extends => Object) {
    method FINALIZE {
        $self->apply_roles($self->roles_for_composition);
    }
}

class Class (roles => [HasMethods, HasAttributes, HasRoles, HasName, HasVersion, HasSuperclass, Instantiable, Dispatchable, Cloneable], extends => Object) {
    # NOTE: this is added afterwards, having it in place during bootstrapping
    # is problematic, and we know the things we're creating at that point are
    # consistent
    # BUILD { }

    method methods {
        my %methods;
        mop::WALKCLASS(
            $self->dispatcher('reverse'),
            sub {
                %methods = (
                    %methods,
                    %{ $_[0]->local_methods },
                );
            }
        );
        return \%methods;
    }

    method attributes {
        my %attrs;
        mop::WALKCLASS(
            $self->dispatcher('reverse'),
            sub {
                %attrs = (
                    %attrs,
                    %{ $_[0]->local_attributes },
                );
            }
        );
        return \%attrs;
    }

    method roles {
        my @roles;
        mop::WALKCLASS(
            $self->dispatcher('reverse'),
            sub {
                push @roles, (
                    map { $_, $_->local_roles }
                        $_[0]->local_roles,
                );
            }
        );
        return @roles;
    }

    method instance_DOES ($other) {
        return $self->instance_isa($other) || $self->instance_does($other);
    }

    method FINALIZE {
        my $stash      = mop::internal::get_stash_for( $self );
        my $dispatcher = $self->dispatcher;

        $self->apply_roles($self->roles_for_composition);

        my $methods = $self->methods;

        %$stash = ();

        foreach my $name ( keys %$methods ) {
            my $method = $methods->{ $name };
            $stash->add_method(
                $name,
                $method->_generate_callable_sub,
            ) unless exists $stash->{ $name };
        }

        $stash->add_method('DESTROY' => mop::internal::generate_DESTROY());
    }
}

1;
