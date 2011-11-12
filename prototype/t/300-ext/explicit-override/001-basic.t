#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;
use lib 't/ext/explicit-override';

use mop;
use explicit::override;

class Foo {
    method foo { 'BASE' }
}
eval <<CLASS;
class FooSub (extends => Foo) {
    override foo => sub { 'SUB' };
}
CLASS

ok(!$@);

is(FooSub()->new->foo, 'SUB');

eval <<CLASS;
class FooSub2 (extends => Foo) {
    method foo { 'SUB2' }
}
CLASS

like(
    $@,
    qr/^Overriding method foo without using override/
);

done_testing;
