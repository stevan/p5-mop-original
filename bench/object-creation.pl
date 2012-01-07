#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark ':hireswallclock', 'cmpthese';

{
    package MopClass;
    use mop;

    class Class {
        has $foo;
        method foo { $foo }
    }
}

{
    package MooseClass;
    use Moose;

    has foo => (is => 'ro');
}

{
    package MooseImmutableClass;
    use Moose;

    has foo => (is => 'ro');

    __PACKAGE__->meta->make_immutable;
}

{
    package MouseClass;
    use Mouse;

    has foo => (is => 'ro');
}

{
    package MouseImmutableClass;
    use Mouse;

    has foo => (is => 'ro');

    __PACKAGE__->meta->make_immutable;
}

cmpthese(100000, {
    mop             => sub { MopClass::Class->new(foo => 'FOO') },
    moose           => sub { MooseClass->new(foo => 'FOO') },
    mouse           => sub { MouseClass->new(foo => 'FOO') },
    moose_immutable => sub { MooseImmutableClass->new(foo => 'FOO') },
    mouse_immutable => sub { MouseImmutableClass->new(foo => 'FOO') },
});
