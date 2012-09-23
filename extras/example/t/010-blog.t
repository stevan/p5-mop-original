#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use lib '../../blib/lib/', '../../blib/arch/';

BEGIN {
    use_ok('Blog');
}

{
    my $blog = Blog->new;
    ok $blog->isa( Blog ), '... isa Blog';
}

done_testing;