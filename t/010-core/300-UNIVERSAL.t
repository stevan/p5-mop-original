#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use mop;

my $got;
class Foo (version => 0.02) {
    method foo ($thing) { $got = $thing }
}

SKIP: { skip "Requires the full mop", keys(%UNIVERSAL::) + 1 if $ENV{PERL_MOP_MINI};
isa_ok(Foo->find_method($_), $::Method)
    for grep { $_ ne 'VERSION' } keys %UNIVERSAL::;
isa_ok(mop::class_of(Foo)->find_method($_), $::Method)
    for qw(VERSION);
}

TODO: { todo_skip "VERSION not yet implemented", 4 if $ENV{PERL_MOP_MINI};
is(Foo->VERSION, 0.02);
is(exception { Foo->VERSION(0.01) }, undef);
like(
    exception { Foo->VERSION(0.03) },
    qr/^\QFoo version 0.03 required--this is only version 0.02/
);
like(
    exception { Foo->VERSION("abc") },
    qr/^\QInvalid version format (non-numeric data)/
);
}

{
    my $foo = Foo->new;

    ok(!$foo->isa('UNIVERSAL'));

    my $code = $foo->can('foo');
    ok($code);
    is(
        exception { $foo->$code('FOO') },
        undef
    );
    is($got, 'FOO');

    ok($foo->DOES(Foo));
    ok(!$foo->DOES('UNIVERSAL'));
    SKIP: { skip "Requires the full mop", 1 if $ENV{PERL_MOP_MINI}; $::Object = $::Object;
    ok($foo->DOES($::Object));
    }
}

done_testing;
