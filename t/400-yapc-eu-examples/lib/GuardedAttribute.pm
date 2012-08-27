use strict;
use warnings;
use mop;

use Data::Dumper;
use Variable::Magic qw[ wizard cast ];

class GuardedAttribute (extends => $::Attribute) {
    has $guard;
    method guard     { $guard }
    method has_guard { defined $guard }
}

class GuardedAttributeClass (extends => $::Class) {

    method attribute_class { GuardedAttribute }

    method create_instance ($args) {
        my $instance = super;

        my $attrs = $::SELF->get_all_attributes;
        foreach my $attr_name ( keys %$attrs ) {
            my $attr = $attrs->{ $attr_name };
            if ( $attr->isa( GuardedAttribute ) && $attr->has_guard ) {
                #warn "found a guarded attribute in '$attr_name'";
                my $guard = $attr->guard;
                my $slots = mop::internal::instance::get_slots( $instance );
                my $datum = $slots->{ $attr_name };
                my $wiz   = wizard(set => sub {
                    die "Value '$_[0]' did not pass the guard" unless $guard->( ${ $_[0] } )
                });
                #warn $slots->{ $attr_name };
                cast $$datum, $wiz;
                $slots->{ $attr_name } = $datum;
                #warn $slots->{ $attr_name };
            }
        }

        $instance;
    }
}

1;