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

1;
