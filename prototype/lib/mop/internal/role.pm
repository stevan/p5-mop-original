package mop::internal::role;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;

sub does {
    my $self = shift;
    my ($role) = @_;
    scalar grep { mop::internal::class::equals( $_, $role ) }
                @{ mop::internal::instance::get_slot_at( $self, '$roles' ) };
}

sub apply {
    my $self = shift;
    my (@roles) = @_;

    my $methods = mop::internal::instance::get_slot_at( $self, '$methods' );
    my $attrs   = mop::internal::instance::get_slot_at( $self, '$attributes' );

    # TODO: conflicts, alias, excludes
    foreach my $role ( @roles ) {
        %$methods = (
            %{ mop::internal::instance::get_slot_at( $role, '$methods' ) },
            %$methods,
        );
        %$attrs = (
            %{ mop::internal::instance::get_slot_at( $role, '$attributes' ) },
            %$attrs,
        );
    }

    return;
}

1;
