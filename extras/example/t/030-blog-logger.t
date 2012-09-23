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
    my $logger = Blog::Logger->new;
    ok $logger->isa( Blog::Logger ), '... isa Blog::Logger';

    ok $logger->can('log'), '... can log';
}

done_testing;