#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

my $role = $::Role->new(
    name => '__ANON__::Role',
    attributes => {
        is_worn => undef,
    },
    methods => {
        remove => sub { shift->is_worn(0) },
    },
);

my $class = $::Class->new(name => 'MyItem::Armor::Helmet');
$role->apply($class);
# XXX: Moose::Util::apply_all_roles doesn't cope with references yet

my $visored = $class->create_instance(is_worn => 0);
ok(!$visored->is_worn, "attribute, accessor was consumed");
$visored->is_worn(1);
ok($visored->is_worn, "accessor was consumed");
$visored->remove;
ok(!$visored->is_worn, "method was consumed");

like($role->name, '__ANON__::Role', "Role has the right name");
ok(mop::class_of($role), "creating an anonymous role satisifes class_of");

{
    my $role;
    {
        my $meta = $::Role->new(
            name => '__ANON__::Role2',
            methods => {
                foo => sub { 'FOO' },
            },
        );

        $role = $meta->name;
        can_ok($role, 'foo');
    }
    ok(!$role->can('foo'));
}

done_testing;
