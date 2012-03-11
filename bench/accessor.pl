#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark ':hireswallclock', 'cmpthese';

use mop;

class MopClass {
    has $foo;
    method foo { $foo }
}

{
    package MooseClass;
    use Moose;
    has foo => (is => 'ro');
}

{
    package MouseClass;
    use Mouse;
    has foo => (is => 'ro');
}

{
    package MooseImmutableClass;
    use Moose;
    has foo => (is => 'ro');
    __PACKAGE__->meta->make_immutable;
}

{
    package MouseImmutableClass;
    use Mouse;
    has foo => (is => 'ro');
    __PACKAGE__->meta->make_immutable;
}

my $mop = MopClass->new(foo => 'FOO');
my $moose = MooseClass->new(foo => 'FOO');
my $mouse = MouseClass->new(foo => 'FOO');
my $moosei = MooseImmutableClass->new(foo => 'FOO');
my $mousei = MouseImmutableClass->new(foo => 'FOO');

cmpthese(1000000, {
    mop             => sub { $mop->foo },
    moose           => sub { $moose->foo },
    mouse           => sub { $mouse->foo },
    moose_immutable => sub { $moosei->foo },
    mouse_immutable => sub { $mousei->foo },
});
