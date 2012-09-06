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
    require mop::full;
    mop::full->import(-into => scalar(caller), @_);
}

BEGIN {
    *WALKCLASS = \&mop::util::WALKCLASS;
    *WALKMETH  = \&mop::util::WALKMETH;
    *class_of  = \&mop::internal::instance::get_class;
    *uuid_of   = \&mop::internal::instance::get_uuid;
}

1;
