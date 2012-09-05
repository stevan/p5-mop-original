package mop::mini;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use mop::mini::syntax;

sub import {
    shift;
    my %options = @_;
    mop::mini::syntax->setup_for( $options{'-into'} // caller )
}

1;
