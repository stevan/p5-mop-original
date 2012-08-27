#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

role Role::Base {
    method foo { 'Role::Base::foo' }
}

role Role::Derived1 (with => [Role::Base]) {
}

role Role::Derived2 (with => [Role::Base]) {
}

is(exception {
    class Class::Test (with => [Role::Derived1, Role::Derived2]) {
    }
}, undef, 'consuming two roles that had consumed the same method is not a conflict');

ok(Role::Base->find_method('foo'), 'Role::Base has method foo');
ok(Role::Derived1->find_method('foo'), 'Role::Derived1 has method foo');
ok(Role::Derived2->find_method('foo'), 'Role::Derived2 has method foo');
ok(Class::Test->find_method('foo'),'Class::Test has method foo');
is(Class::Test->new->foo, 'Role::Base::foo', 'got the right value from the method foo');

# now the same but for attributes

role Role::Base2 {
    has $foo = 'Role::Base2::foo';

    method foo { $foo }
}

role Role::Derived3 (with => [Role::Base2]) {
}

role Role::Derived4 (with => [Role::Base2]) {
}

is(exception {
    class Class::Test2 (with => [Role::Derived3, Role::Derived4]) {
    }
}, undef, 'consuming two roles that had consumed the same attribute is not a conflict');

ok(Role::Base2->find_attribute('$foo'), 'Role::Base2 has method foo');
ok(Role::Derived3->find_attribute('$foo'), 'Role::Derived3 has method foo');
ok(Role::Derived4->find_attribute('$foo'), 'Role::Derived4 has method foo');
ok(Class::Test2->find_attribute('$foo'), 'Class::Test2 has method foo');

is(Class::Test2->new->foo, 'Role::Base2::foo', 'got the right value from the method foo');

done_testing;

