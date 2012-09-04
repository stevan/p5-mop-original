package mop::util;

use 5.014;
use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';
}

sub WALKCLASS {
    my ($dispatcher, $solver) = @_;
    { $solver->( $dispatcher->() || return ); redo }
}

sub WALKMETH {
    my ($dispatcher, $method_name) = @_;
    { ( $dispatcher->() || return )->get_local_methods->{ $method_name } || redo }
}

sub class_of { mop::internal::instance::get_class( shift ) }
sub uuid_of  { mop::internal::instance::get_uuid( shift )  }

1;
