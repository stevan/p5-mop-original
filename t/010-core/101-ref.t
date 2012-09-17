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
    local $TODO = 'This will actually probably be something more specific then SCALAR in the end';
    is(reftype($foo), 'SCALAR', '... got the value from reftype we expected');
    is(reftype(Foo), 'SCALAR', '... got the value from reftype we expected');
}

done_testing;
