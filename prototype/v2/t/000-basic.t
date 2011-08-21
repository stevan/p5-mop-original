#!perl

use strict;
use warnings;

use Test::More;

use mop;

ok $::Class, '... we have the class Class';
ok $::Object, '... we have the class Object';

is $::Object->class, $::Class, '... the class of Object is Class';
is $::Class->class, $::Class, '... the class of Class is Class';

ok $::Class->is_subclass_of( $::Object ), '... class Class is a subclass of Object';
ok !$::Class->is_subclass_of( $::Class ), '... class Class is not a subclass of Class';

ok $::Class->is_a( $::Object ), '... class Class is a Object';
ok $::Class->is_a( $::Class ), '... class Class is a Class';

done_testing;