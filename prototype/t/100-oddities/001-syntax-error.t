#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Moose;

use mop;

eval q{
    class 'Foo' => sub {
        has( my $bar );

        method 'bar' => sub { $baz };
    };
};

like "$@", qr/^Global symbol \"\$baz\" requires explicit package name/, '... got the syntax error we expected';


done_testing