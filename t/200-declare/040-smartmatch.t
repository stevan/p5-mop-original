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

TODO: { todo_skip "overloading not yet implemented", 11 if $ENV{PERL_MOP_MINI};
ok(  Foo->new ~~ Foo  );
ok(!(Foo->new ~~ Bar) );
ok(!(Foo->new ~~ Baz) );
ok(!(Foo->new ~~ Quux));

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

ok(  Bar->new ~~ Foo  );
ok(  Bar->new ~~ Bar  );
ok(!(Bar->new ~~ Baz) );
ok(!(Bar->new ~~ Quux));

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
}

done_testing;
