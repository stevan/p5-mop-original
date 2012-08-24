#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use 5.014;

use mop;

class Foo { }
class Bar (extends => Foo) { }
class Baz (extends => Bar) { }
class Quux { }

{
    my $found;
    given (Foo->new) {
        when (Quux) { $found = "Quux" }
        when (Baz)  { $found = "Baz" }
        when (Bar)  { $found = "Bar" }
        when (Foo)  { $found = "Foo" }
        default     { $found = "default" }
    }
    is($found, "Foo");
}

{
    my $found;
    given (Bar->new) {
        when (Quux) { $found = "Quux" }
        when (Baz)  { $found = "Baz" }
        when (Bar)  { $found = "Bar" }
        when (Foo)  { $found = "Foo" }
        default     { $found = "default" }
    }
    is($found, "Bar");
}

{
    my $found;
    given (Bar->new) {
        when (Quux) { $found = "Quux" }
        when (Baz)  { $found = "Baz" }
        when (Foo)  { $found = "Foo" }
        default     { $found = "default" }
    }
    is($found, "Foo");
}

done_testing;
