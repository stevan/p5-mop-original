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
    my $editor = Blog::Editor->new;
    ok $editor->isa( Blog::Editor ), '... isa Blog::Editor';

    ok $editor->can('invoke'), '... can invoke';
    ok $editor->can('prompt'), '... can prompt';
}

done_testing;