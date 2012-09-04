#!/usr/bin/env perl
# Source: moose.git/t/roles/create_role.t
use strict;
use warnings;
use Test::More;
use mop;

my $role = $::Role->new(
    name => 'MyItem::Role::Equipment',
    attributes => {
        is_worn => $::Attribute->new(name => '$is_worn'), # is => 'rw', isa => 'Bool',
    },
    methods => {
        is_worn => $::Method->new(name => 'is_worn', body => sub {
            if(@_) {
                my $value = shift;
                mop::internal::instance::set_slot_at($::SELF, '$is_worn', \ $value);
            }
            else {
                ${ mop::internal::instance::get_slot_at($::SELF, '$is_worn') };
            }
        }),
        remove => $::Method->new(name => 'remove', body => sub {
            $::SELF->is_worn(0);
        }),
    },
);
$role->FINALIZE;

my $class = $::Class->new(
    name => 'MyItem::Armor::Helmet',
    roles => [ $role ],
);
$class->FINALIZE;

my $visored = $class->new(is_worn => 0);
ok(!$visored->is_worn, "attribute, accessor was consumed");
$visored->is_worn(1);
ok($visored->is_worn, "accessor was consumed");
$visored->remove;
ok(!$visored->is_worn, "method was consumed");

my $composed_role = $::Role->new(
    name => 'MyItem::Role::Equipment2',
    roles => [ $role ],
);

ok($composed_role->instance_does($role), "Role composed into role");

done_testing;