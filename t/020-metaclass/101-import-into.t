#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    package My::Extension;
    use mop ();

    sub import {
        mop->import(-into => scalar(caller));
    }

    $INC{'My/Extension.pm'} = 1;
}

BEGIN {
    package My::Custom::Extension;
    use mop;

    class CustomClass (extends => $::Class) { }

    sub import {
        mop->import(-into => scalar(caller), -metaclass => CustomClass);
    }

    $INC{'My/Custom/Extension.pm'} = 1;
}

{
    package Foo;
    use My::Extension;

    class Foo { }
}

{
    isa_ok(Foo::Foo, $::Class);
}

{
    package Bar;
    use My::Custom::Extension;

    class Bar { }
}

{
    isa_ok(Bar::Bar, My::Custom::Extension::CustomClass);
}

done_testing;
