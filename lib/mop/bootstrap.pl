use strict;
use warnings;
use 5.014;

# implement all of UNIVERSAL here, because the mop's dispatcher should
# not be using UNIVERSAL at all
class Object {
    method isa  ($other) {
        ref($other) && ( $class == $other || $class->is_subclass_of($other) )
    }
    method does ($other) {
        ref($other) && ( $class->does_role($other) )
    }
    # XXX ideally, ->can would return a method object, which would do the
    # right thing when used as a coderef (so that
    # if (my $foo = $obj->can('foo')) { $obj->$foo(...) }
    # and similar things work as expected), but as far as i can tell,
    # overloading doesn't currently work with anonymous packages
    method can  ($name)  {
        my $method = $class->find_method( $name );
        return sub { $method->execute( @_ ) }
            if $method;
        return;
    }
    method DOES ($other) { $self->isa($other) || $self->does($other) }
}

role Cloneable {
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

        # XXX swap out later
        # %params = (
        #     (map {
        #         $_->get_param_name => mop::internal::instance::get_slot_at(
        #             $self, $_->get_name
        #         )
        #     } values %{ $class->get_all_attributes }),
        #     %params,
        # );
        # return $class->new(%params);
    }
}

class Method (extends => Object, roles => [Cloneable]) {
    has $name;
    has $body;

    method get_name ()      { $name }
    method get_body ()      { $body }

    method execute  (@args) {
        mop::internal::execute_method( $self, @args )
    }
}

class Attribute (extends => Object, roles => [Cloneable]) {
    has $name;
    has $initial_value;

    method get_name                       () { $name }
    method get_initial_value              () { $initial_value }

    method get_initial_value_for_instance () {
        my $value = ${ $self->get_initial_value };
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
    method prepare_constructor_value_for_instance ($val) { $val }
    method get_param_name                 () { $self->get_name =~ s/^\$//r }
}

role HasMethods {
    has $methods = {};

    method get_local_methods ()        { $methods }

    method method_class      ()        { $::Method }

    method find_method       ($name)   {
        $self->get_all_methods->{$name}
    }
    method get_all_methods   ()        { $self->get_local_methods }

    method add_method        ($method) {
        $self->get_local_methods->{$method->get_name} = $method;
    }
}

role HasAttributes {
    has $attributes = {};

    method get_local_attributes ()           { $attributes }

    method attribute_class      ()           { $::Attribute }

    method find_attribute       ($name)      {
        $self->get_all_attributes->{$name}
    }
    method get_all_attributes   ()           { $self->get_local_attributes }

    method add_attribute        ($attribute) {
        $self->get_local_attributes->{$attribute->get_name} = $attribute;
    }
}

role HasRoles {
    has $roles = [];

    method get_local_roles           ()       { $roles }
    method get_roles_for_composition ()       {
        [ map { $_, @{ $_->get_local_roles } } @{ $self->get_local_roles } ]
    }
    method get_all_roles             ()       {
        [ map { $_, @{ $_->get_local_roles } } @{ $self->get_local_roles } ]
    }

    method does_role                 ($role) {
        scalar grep { $_ == $role } @{ $self->get_all_roles }
    }
}

role HasName {
    has $name;

    method get_name () { $name }
}

# XXX splitting this from HasName probably doesn't make sense, since VERSION
# calls $self->get_name. maybe we just want a single HasIdentity role?
role HasVersion {
    has $version;
    has $authority;

    # XXX need to figure out what to do about BUILD in roles
    # this logic is in BUILD for Class and Role directly for now
    # BUILD {
        # coerce $version to a version object
        # ...
    # }

    method get_version   ()             { $version }
    method get_authority ()             { $authority }

    method set_version   ($new_version) { $version = $new_version }

    # XXX this logic is not nearly right, it should really use the logic
    # used by the current UNIVERSAL::VERSION, but UNIVERSAL::VERSION looks
    # up the class's version in $VERSION, which isn't what we want
    method VERSION       ($new_version) {
        my $ver = $self->get_version;

        if ( @_ ) {
            die "Invalid version format (non-numeric data)"
                unless version::is_lax( $new_version );

            my $req = version->parse( $new_version );

            if ( $ver < $req ) {
                die sprintf ("%s version %s required--".
                        "this is only version %s", $self->get_name,
                        $req->stringify, $ver->stringify);
            }
        }

        return $ver;
    }
}

# and this one calls get_mro - should probably rethink some of these splits
role HasSuperclass {
    has $superclass;

    # XXX need to figure out what to do about BUILD in roles
    # this logic is in BUILD for Class and Role directly for now
    # BUILD {
        # set default base object
        # metaclass compatibility checking
        # ...
    # }

    method get_superclass       ()       { $superclass }
    method set_superclass       ($new)   { $superclass = $new }

    method base_object_class    ()       { Object }

    method get_compatible_class ($other) {
        # replace the class with a subclass of itself
        return $other if $other->is_subclass_of( $self );
        # it's already okay
        return $self  if $self->is_subclass_of( $other ) || $other == $self;
        # reconciling this group of metaclasses isn't possible
        return;
    }
    method is_subclass_of       ($super) {
        my @mro = @{ $self->get_mro };
        shift @mro;
        return scalar grep { $super == $_ } @mro;
    }
}

role Instantiable {
    has $constructor;
    has $destructor;

    method get_constructor ()        { $constructor }
    method get_destructor  ()        { $destructor }
    method set_constructor ($method) { $constructor = $method }
    method set_destructor  ($method) { $destructor = $method }

    method create_instance ($params) {
        my $data = {};

        my $attrs = $self->get_all_attributes;
        foreach my $attr_name ( keys %$attrs ) {
            unless ( exists $data->{ $attr_name } ) {
                my $param_name = $attrs->{ $attr_name }->get_param_name;
                if ( exists $params->{ $param_name } ) {
                    my $value = $params->{ $param_name };
                    $data->{ $attr_name } = $attrs->{$attr_name}->prepare_constructor_value_for_instance(\$value);
                }
                else {
                    $data->{ $attr_name } = $attrs->{$attr_name}->get_initial_value_for_instance;
                }

            }
        }

        my $stash = mop::internal::get_stash_for( $self );
        die "Could not find stash for class(" . $self->get_name . ")"
            unless $stash;

        $stash->bless(mop::internal::instance::create( \$self, $data ));
    }

    method new             (%params) {
        my $instance = $self->create_instance( \%params );
        mop::WALKCLASS(
            $self->get_dispatcher('reverse'),
            sub {
                my $meta = shift;
                my $constructor = $meta->get_constructor;
                return unless $constructor;
                $constructor->execute($instance, \%params);
                return;
            }
        );
        $instance;
    }
}

role Dispatchable {
    method get_mro        ()      {
        my $super = $self->get_superclass;
        return [ $self, $super ? @{ $super->get_mro } : () ]
    }
    method get_dispatcher ($type) {
        return sub { state $mro = $self->get_mro; shift @$mro }
            unless $type;
        return sub { state $mro = $self->get_mro; pop   @$mro }
            if $type eq 'reverse';
    }
}

class Role (roles => [HasMethods, HasAttributes, HasRoles, HasName, HasVersion, Cloneable], extends => Object) {
    method FINALIZE () {
        # XXX factor this out
        my $local_methods = $self->get_local_methods;
        my $local_attributes = $self->get_local_attributes;
        my $roles = $self->get_roles_for_composition; # XXX?
        foreach my $role ( @$roles ) {
            my $methods = $role->get_local_methods;
            foreach my $name ( keys %$methods ) {
                $self->add_method( $methods->{$name}->clone )
                    unless exists $local_methods->{$name};
            }
            my $attributes = $role->get_local_attributes;
            foreach my $name ( keys %$attributes ) {
                $self->add_attribute( $attributes->{$name}->clone )
                    unless exists $local_attributes->{$name};
            }
        }
    }
}

class Class (roles => [HasMethods, HasAttributes, HasRoles, HasName, HasVersion, HasSuperclass, Instantiable, Dispatchable, Cloneable], extends => Object) {
    method get_all_methods () {
        my %methods;
        mop::WALKCLASS(
            $::SELF->get_dispatcher('reverse'),
            sub {
                %methods = (
                    %methods,
                    %{ $_[0]->get_local_methods },
                );
            }
        );
        return \%methods;
    }
    method get_all_attributes () {
        my %attrs;
        mop::WALKCLASS(
            $self->get_dispatcher('reverse'),
            sub {
                %attrs = (
                    %attrs,
                    %{ $_[0]->get_local_attributes },
                );
            }
        );
        return \%attrs;
    }
    method get_all_roles () {
        my @roles;
        mop::WALKCLASS(
            $self->get_dispatcher('reverse'),
            sub {
                push @roles, (
                    map { $_, @{ $_->get_local_roles } }
                        @{ $_[0]->get_local_roles },
                );
            }
        );
        return \@roles;
    }

    method FINALIZE () {
        my $stash      = mop::internal::get_stash_for( $self );
        my $dispatcher = $self->get_dispatcher;

        %$stash = ();

        my $local_methods = $self->get_local_methods;
        my $local_attributes = $self->get_local_attributes;
        my $roles = $self->get_roles_for_composition; # XXX?
        foreach my $role ( @$roles ) {
            my $methods = $role->get_local_methods;
            foreach my $name ( keys %$methods ) {
                $self->add_method( $methods->{$name}->clone )
                    unless exists $local_methods->{$name};
            }
            my $attributes = $role->get_local_attributes;
            foreach my $name ( keys %$attributes ) {
                $self->add_attribute( $attributes->{$name}->clone )
                    unless exists $local_attributes->{$name};
            }
        }

        my $methods = $self->get_all_methods;
        foreach my $name ( keys %$methods ) {
            my $method = $methods->{ $name };
            $stash->add_method(
                $name,
                # XXX
                sub { mop::internal::execute_method($method, @_) },
                # sub { $method->execute( @_ ) }
            ) unless exists $stash->{ $name };
        }

        $stash->add_method('DESTROY' => sub {
            my $invocant = shift;
            my $class    = mop::internal::instance::get_class( $invocant );
            return unless $class; # likely in global destruction ...
            mop::WALKCLASS(
                $class->get_dispatcher(),
                sub {
                    my $dispatcher = $_[0]->get_destructor;
                    return unless $dispatcher;
                    $dispatcher->execute($invocant);
                    return;
                }
            );
        });
    }
}

1;
