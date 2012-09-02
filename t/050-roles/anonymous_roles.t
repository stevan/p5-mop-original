#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use mop;

my $role = $::Role->new(
    name => '__ANON__::Role',
    attributes => {
        is_worn => $::Attribute->new(name => '$is_worn'),
    },
    methods => {
        is_worn => $::Method->new(name => 'is_worn', body => sub {
            mop::internal::instance::set_slot_at($::SELF, '$is_worn', \$_[0])
                if @_;
            return ${ mop::internal::instance::get_slot_at($::SELF, '$is_worn') };
        }),
        remove => $::Method->new(name => 'remove', body => sub {
            $::SELF->is_worn(0)
        }),
    },
);

my $class = $::Class->new(name => 'MyItem::Armor::Helmet');
$class->add_roles($role);
$class->FINALIZE;

# XXX: Moose::Util::apply_all_roles doesn't cope with references yet

my $visored = $class->new(is_worn => 0);
ok(!$visored->is_worn, "attribute, accessor was consumed");
$visored->is_worn(1);
ok($visored->is_worn, "accessor was consumed");
$visored->remove;
ok(!$visored->is_worn, "method was consumed");

is($role->get_name, '__ANON__::Role', "Role has the right name");
ok(mop::class_of($role), "creating an anonymous role satisifes class_of");

done_testing;
