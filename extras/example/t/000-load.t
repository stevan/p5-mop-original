#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib '../../blib/lib/', '../../blib/arch/';

BEGIN {
    use_ok('Blog');
}

done_testing;