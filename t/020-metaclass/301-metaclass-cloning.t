#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

class Foo {
    has $foo;
    method foo { $foo * 2 }
}

{
    my $FooClone = Foo->clone;
    $FooClone->FINALIZE;
    is($FooClone->name, 'Foo');
    is($FooClone->find_method('foo'), Foo->find_method('foo'));
    is($FooClone->find_attribute('$foo'), Foo->find_attribute('$foo'));
    isnt($FooClone, Foo);
    isnt(mop::uuid_of($FooClone), mop::uuid_of(Foo));
    is(mop::class_of($FooClone), mop::class_of(Foo));

    my $foo = Foo->new;
    my $foo_clone = $FooClone->new;
    is(mop::class_of($foo), Foo);
    is(mop::class_of($foo_clone), $FooClone);
}

role FooRole {
    has $foo;
    method foo { $foo * 2 }
}

{
    my $FooClone = FooRole->clone;
    is($FooClone->name, 'FooRole');
    is($FooClone->find_method('foo'), FooRole->find_method('foo'));
    is($FooClone->find_attribute('$foo'), FooRole->find_attribute('$foo'));
    isnt($FooClone, FooRole);
    isnt(mop::uuid_of($FooClone), mop::uuid_of(FooRole));
    is(mop::class_of($FooClone), mop::class_of(FooRole));
}

{
    my $method = Foo->find_method('foo');
    Foo->add_method($method->clone(name => 'foo_clone'));
    Foo->FINALIZE;
    my $foo = Foo->new(foo => 23);
    is($foo->foo, 46);
    is($foo->foo_clone, 46);
}

{
    my $attribute = Foo->find_attribute('$foo');
    Foo->add_attribute($attribute->clone(name => '$foo_clone'));
    Foo->FINALIZE;
    my $foo = Foo->new(foo_clone => 21);
    is(${ mop::internal::instance::get_slot_at($foo, '$foo_clone') }, 21);
}

done_testing;
