package mop::mini;

use 5.014;
use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    $::SELF   = undef;
    $::CLASS  = undef;
    $::CALLER = undef;
}

use mop::mini::class;
use mop::mini::syntax;
use mop::util;

sub import {
    shift;
    my %options = @_;
    mop::mini::syntax->setup_for( $options{'-into'} // caller )
}

1;

__END__
