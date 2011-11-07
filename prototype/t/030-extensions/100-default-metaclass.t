#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

class Meta1 (extends => $::Class) { }
class Meta2 (extends => $::Class) { }
class Meta3 (extends => $::Class) { }

class Foo { }
{
    use mop -metaclass => Meta1;
    class Foo1 { }
    {
        use mop -metaclass => Meta2;
        class Foo2 { }
        class Foo3 (metaclass => Meta3) { }
    }
    class Bar1 { }
    class Bar3 (metaclass => Meta3) { }
}
class Bar { }
class Baz3 (metaclass => Meta3) { }

{
    ok(Foo->isa($::Class));
    ok(Foo1->isa(Meta1));
    ok(Foo2->isa(Meta2));
    ok(Foo3->isa(Meta3));
    ok(Bar1->isa(Meta1));
    ok(Bar3->isa(Meta3));
    ok(Bar->isa($::Class));
    ok(Baz3->isa(Meta3));
}

done_testing;
