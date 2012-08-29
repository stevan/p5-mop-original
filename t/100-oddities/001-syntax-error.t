#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

{
    eval q{
        class Foo {
            has $bar;

            method bar { $baz }
        }
    };

    like "$@", qr/^Global symbol \"\$baz\" requires explicit package name/, '... got the syntax error we expected';
}

{
    eval 'class Foo { method foo (€bar) { 1 } }';
    like(
        "$@",
        qr/expected valid sigil/,
        '... signature parse failure works'
    );
}

{
    eval 'class Boo { method foo ($bar { 1 } }';
    like(
        "$@",
        qr/expected comma or closing/,
        '... signature parse failure works'
    );
}

{
    eval 'class Too { method foo (%1foo) { 1 }}';
    like(
        "$@",
        qr/invalid identifier/,
        '... method signature failure works'
    );
}

{
    eval 'class Goo } { method foo ($bar { 1 } }';
    like(
        "$@",
        qr/expected '{'/,
        '... class metadata parse failure works'
    );
}

done_testing
