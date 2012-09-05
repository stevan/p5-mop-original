package mop::parser;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Devel::CallParser;

use XSLoader;
XSLoader::load('mop', $VERSION);

1;
