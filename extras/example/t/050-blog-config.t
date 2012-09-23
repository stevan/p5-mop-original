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
    my $config = Blog::Config->new( config_file => 't/data/my_test_config.yml' );
    ok $config->isa( Blog::Config ), '... isa Blog::Config';

    is $config->get('storage'), 't/data/blog.json', '... got the right value from the config';
    is $config->get('editor'), '/usr/bin/pico', '... got the right value from the config';
}

like exception {
    Blog::Config->new( config_file => 't/data/my_non_existant_test_config.yml' );
}, qr/Could not find config file named\: t\/data\/my_non_existant_test_config\.yml/, '... got the expected error';


done_testing;