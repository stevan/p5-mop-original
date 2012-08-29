use strict;
use warnings;
use mop;

use Variable::Magic qw[ wizard cast ];

role MetaAttributeWithGuard {
    has $guard;

    method guard     { $guard }
    method has_guard { defined $guard }

    method get_initial_value_for_instance {
        my $value = super;
        return $value unless $self->has_guard;
        $self->_add_guard_to_slot( $value );
    }

    method prepare_constructor_value_for_instance ( $value ) {
        return super( $value ) unless $self->has_guard;
        $self->_add_guard_to_slot( $value );
    }

    method _add_guard_to_slot ( $value ) {
        my $guard = $self->guard;
        my $wiz   = wizard(set => sub {
            die "Value '$_[0]' did not pass the guard" unless $guard->( ${ $_[0] } )
        });
        cast $$value, $wiz;
        $value;
    }
}

class GuardedAttribute (extends => $::Attribute, with => [MetaAttributeWithGuard]) {}

class GuardedAttributeClass (extends => $::Class) {
    method attribute_class { GuardedAttribute }
}

class GuardedAttributeRole (extends => $::Role) {
    method attribute_class { GuardedAttribute }
}

1;