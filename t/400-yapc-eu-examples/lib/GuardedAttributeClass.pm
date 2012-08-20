use strict;
use warnings;
use mop;

use Data::Dumper;

class GuardedAttribute (extends => $::Attribute) {
    has $guard;
    method guard { $guard }
}

class GuardedAttributeClass (extends => $::Class) {

    method attribute_class { GuardedAttribute }

    method create_instance ($args) {
        my $instance = super;

        my $attrs = $::SELF->get_all_attributes;
        foreach my $attr_name ( keys %$attrs ) {
            my $attr = $attrs->{ $attr_name };
            if ( $attr->isa( GuardedAttribute ) ) {
                my $guard = $attr->guard;
                my $data  = mop::internal::instance::get_slot_at( $instance, $attr_name );
                warn Dumper [ $attr_name, $guard, $data ];
            }
        }
    }
}

1;