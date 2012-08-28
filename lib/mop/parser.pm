package mop::parser;

use 5.014;
use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';
}

use XSLoader;
BEGIN { XSLoader::load(__PACKAGE__, our $VERSION) }

1;
