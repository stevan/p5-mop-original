#!/usr/bin/perl

use strict;
use warnings;

use Scalar::Util qw[ reftype ];

use Test::More;

use mop;

class Foo {}

my $foo = Foo->new;
is(ref($foo), 'Foo', '... got the value from ref we expected');
is(ref(Foo), ($ENV{PERL_MOP_MINI} ? 'mop::mini::class' : 'mop::bootstrap::full::Class'), '... got the value from ref we expected');

TODO: {
    local $TODO = "can't change reftype yet";
    is(reftype($foo), 'INSTANCE', '... got the value from reftype we expected');
    is(reftype(Foo), 'INSTANCE', '... got the value from reftype we expected');
}

done_testing;
