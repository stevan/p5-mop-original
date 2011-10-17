#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

http://svn.openfoundry.org/pugs/ext/Test-Builder

=cut

use lib 't/ext';

BEGIN {
    use_ok( 'Test::Builder' );
}

done_testing;