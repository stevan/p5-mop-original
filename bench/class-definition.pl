#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark ':hireswallclock', 'cmpthese';

use mop ();
use Moose ();
use Mouse ();

use constant N => 10000;
use constant DEBUG => 0;

my @mop_classes   = map { mop_class($_) } 1..N;
my @moose_classes = map { moose_class($_) } 1..N;
my @mouse_classes = map { mouse_class($_) } 1..N;
my @moose_immutable_classes = map { moose_class($_, 1) } 1..N;
my @mouse_immutable_classes = map { mouse_class($_, 1) } 1..N;

{
    my ($mop, $moose, $mouse, $moosei, $mousei) = (0) x 5;
    cmpthese(N, {
        mop => sub {
            eval $mop_classes[$mop++];
            if (DEBUG) {
                die $@ if $@;
                my $class = eval "MopClass::m$mop()";
                my $obj = $class->new(foo => 'FOO');
                die unless $obj->foo eq 'FOO';
            }
        },
        moose => sub {
            eval $moose_classes[$moose++];
            if (DEBUG) {
                die $@ if $@;
                my $obj = "MooseClass$moose"->new(foo => 'FOO');
                die unless $obj->foo eq 'FOO';
            }
        },
        mouse => sub {
            eval $mouse_classes[$mouse++];
            if (DEBUG) {
                die $@ if $@;
                my $obj = "MouseClass$mouse"->new(foo => 'FOO');
                die unless $obj->foo eq 'FOO';
            }
        },
        moose_immutable => sub {
            eval $moose_immutable_classes[$moosei++];
            if (DEBUG) {
                die $@ if $@;
                my $obj = "MooseClass${\($moosei+N)}"->new(foo => 'FOO');
                die unless $obj->foo eq 'FOO';
            }
        },
        mouse_immutable => sub {
            eval $mouse_immutable_classes[$mousei++];
            if (DEBUG) {
                die $@ if $@;
                my $obj = "MouseClass${\($mousei+N)}"->new(foo => 'FOO');
                die unless $obj->foo eq 'FOO';
            }
        },
    });
}

sub mop_class {
    my ($i) = @_;
    return sprintf(<<'CLASS', $i);
    use mop;
    class MopClass::m%d {
        has $foo;
        method foo { $foo }
    }
CLASS
}

sub moose_class {
    my ($i, $immutable) = @_;
    $i += N if $immutable;
    return sprintf(<<'CLASS', $i, $immutable ? "__PACKAGE__->meta->make_immutable;" : "");
    package MooseClass%d;
    use Moose;

    has foo => (is => 'ro');
    %s
CLASS
}

sub mouse_class {
    my ($i, $immutable) = @_;
    $i += N if $immutable;
    return sprintf(<<'CLASS', $i, $immutable ? "__PACKAGE__->meta->make_immutable;" : "");
    package MouseClass%d;
    use Mouse;

    has foo => (is => 'ro');
    %s
CLASS
}
