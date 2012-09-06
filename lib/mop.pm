package mop;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use mop::internal::instance;
use mop::util;

sub import {
    shift;
    # XXX this is just here for testing for now
    if ($ENV{PERL_MOP_MINI}) {
        require mop::mini;
        mop::mini->import(-into => scalar(caller), @_);
    }
    else {
        require mop::full;
        mop::full->import(-into => scalar(caller), @_);
    }
}

BEGIN {
    *WALKCLASS = \&mop::util::WALKCLASS;
    *WALKMETH  = \&mop::util::WALKMETH;
    *class_of  = \&mop::internal::instance::get_class;
    *uuid_of   = \&mop::internal::instance::get_uuid;
}

1;
