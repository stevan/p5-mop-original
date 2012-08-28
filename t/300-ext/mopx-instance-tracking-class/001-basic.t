#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/mopx-instance-tracking-class';

BEGIN {
    eval { require Set::Object::Weak; 1 }
        or plan skip_all => "Set::Object::Weak is required for this test";
}

use mop;
use mopx::instance::tracking::class;

class Foo {
}

sub is_instances {
    my ($class, @instances) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply(
        [ sort { $a <=> $b } $class->instances ],
        [ sort { $a <=> $b } @instances ]
    );
}

my $foo = Foo->new();
is_instances(Foo, $foo);

do {
    my $bar = Foo->new();
    is_instances(Foo, $foo, $bar);
};

is_instances(Foo, $foo);

class Person {
    has $name;
}

my $stevan = Person->new(name => 'Stevan');
my $jesse = Person->new(name => 'Jesse');

is_instances(Person, $stevan, $jesse);
is_instances(Foo, $foo);

done_testing();

