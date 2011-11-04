#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/Class-MOPX';

BEGIN {
    package FollowPBP;

    use Class::MOPX;

    class Attribute (extends => Class::MOPX::Attribute) {
        has $reader;
        has $writer;
        has $accessor;

        BUILD ($params) {
            if (my $is = $params->{is}) {
                (my $name = $self->get_name) =~ s/^\$//;
                if ($is eq 'ro') {
                    $reader = 'get_' . $name;
                }
                elsif ($is eq 'rw') {
                    $reader = 'get_' . $name;
                    $writer = 'set_' . $name;
                    $accessor = undef;
                }
            }
        }
    }

    class Class (extends => Class::MOPX::Class) {
        method attribute_class { Attribute }
    }

    sub import { mop->import(-metaclass => Class) }

    $INC{'FollowPBP.pm'} = 1;
}

{
    use Class::MOPX;
    use FollowPBP;

    class Foo {
        has $foo (is => 'ro');
        has $bar (is => 'rw');
    }
}

{
    my $foo = Foo->new(foo => "FOO", bar => "BAR");
    can_ok($foo, 'get_foo');
    can_ok($foo, 'get_bar');
    can_ok($foo, 'set_bar');
    ok(!$foo->can('foo'));
    ok(!$foo->can('bar'));
    is($foo->get_foo, "FOO");
    is($foo->get_bar, "BAR");
}

done_testing;
