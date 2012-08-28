#!/usr/bin/perl
# Source: moose.git/t/roles/overriding.t

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use mop;

BEGIN { $SIG{__DIE__} = \&Carp::confess }

sub apply_roles_to {
    my($target, @roles) = @_;
    my $roles = mop::internal::instance::get_slot_at( $target, '$roles' );
    mop::internal::instance::set_slot_at( $target, '$roles', \ [@$roles, @roles] );
    $target->FINALIZE;
}

role Role::A {
    method bar { 'Role::A::bar' }
}

role Role::B {
    method xxy { 'Role::B::xxy' }
}

role Role::C {
    method foo { 'Role::C::foo' }
    method zot { 'Role::C::zot' }
}

class Class::A {
    method zot { 'Class::A::zot' }
}

{
    ::is( ::exception {
        apply_roles_to Class::A, Role::A, Role::B;
    }, undef, "define role C" );
}

{
    ::is( ::exception {
        apply_roles_to Class::A, Role::C;
    }, undef, "define class A" );
}

can_ok( Class::A->new, qw(foo bar xxy zot) );

is( Class::A->new->foo, "Role::C::foo",  "... got the right foo method" );
is( Class::A->new->zot, "Class::A::zot", "... got the right zot method" );
is( Class::A->new->bar, "Role::A::bar",  "... got the right bar method" );
is( Class::A->new->xxy, "Role::B::xxy",  "... got the right xxy method" );

role Role::A::Shadow ( does => [Role::A] ) {
    # check that when a role is added to another role
    # that the consumer's method shadows just like for classes.
    method bar { 'Role::A::Shadow::bar' }
}

class Class::A::Shadow {
}

{
    ::is( ::exception {
        apply_roles_to Class::A::Shadow, Role::A::Shadow;
    }, undef, '... did fufill the requirement of &bar method' );
}

can_ok( Class::A::Shadow->new, qw(bar) );

is( Class::A::Shadow->new->bar, 'Role::A::Shadow::bar', "... got the right bar method" );

role Role::D {
    # check that when two roles are composed, they conflict
    # but the composing role can resolve that conflict

    method foo { 'Role::D::foo' }
    method bar { 'Role::D::bar' }
}

role Role::E {
    method foo { 'Role::E::foo' }
    method xxy { 'Role::E::xxy' }
}

role Role::F {
    method foo { 'Role::F::foo' }
    method zot { 'Role::F::zot' }
}

{
    ::is( ::exception {
        apply_roles_to Role::F, Role::D, Role::E;
    }, undef, "define role Role::F" );
}

class Class::B {
    method zot { 'Class::B::zot' }
}

{
    ::is( ::exception {
        apply_roles_to Class::B, Role::F;
    }, undef, "define class Class::B" );
}

can_ok( Class::B->new, qw(foo bar xxy zot) );

is( Class::B->new->foo, "Role::F::foo",  "... got the &foo method okay" );
is( Class::B->new->zot, "Class::B::zot", "... got the &zot method okay" );
is( Class::B->new->bar, "Role::D::bar",  "... got the &bar method okay" );
is( Class::B->new->xxy, "Role::E::xxy",  "... got the &xxy method okay" );

TODO: {
    todo_skip 'requires_method() does not exist', 1;
    ok(Role::F->requires_method('foo'), '... Role::F fufilled the &foo requirement');
}

role Role::D::And::E::NoConflict {
    # check that a conflict can be resolved
    # by a role, but also new ones can be
    # created just as easily ...
    method foo { 'Role::D::And::E::NoConflict::foo' }  # this overrides ...
    method xxy { 'Role::D::And::E::NoConflict::xxy' }  # and so do these ...
    method bar { 'Role::D::And::E::NoConflict::bar' }
}

{
    ::is( ::exception {
        apply_roles_to Role::D::And::E::NoConflict, Role::D, Role::E;
    }, undef, "... define role Role::D::And::E::NoConflict" );
}

TODO: {
    todo_skip 'requires_method() does not exist', 3;
    ok(!Role::D::And::E::NoConflict->requires_method('foo'), '... Role::D::And::E::NoConflict fufilled the &foo requirement');
    ok(!Role::D::And::E::NoConflict->requires_method('xxy'), '... Role::D::And::E::NoConflict fulfilled the &xxy requirement');
    ok(!Role::D::And::E::NoConflict->requires_method('bar'), '... Role::D::And::E::NoConflict fulfilled the &bar requirement');
}

role Role::H {
    # conflict propagation
    method foo { 'Role::H::foo' }
    method bar { 'Role::H::bar' }
}

role Role::J {
    method foo { 'Role::J::foo' }
    method xxy { 'Role::J::xxy' }
}

role Role::I {
    method zot { 'Role::I::zot' }
    method zzy { 'Role::I::zzy' }
}

{
    ::is( ::exception {
        apply_roles_to Role::I, Role::J, Role::H; # conflict between 'foo's here
    }, undef, "define role Role::I" );
}

class Class::C {
    method zot { 'Class::C::zot' }
}

TODO: {
    local $TODO = 'MOP does not detect conflicts yet';
    ::like( ::exception {
        apply_roles_to Class::C, Role::I;
    }, qr/Due to a method name conflict in roles 'Role::H' and 'Role::J', the method 'foo' must be implemented or excluded by 'Class::C'/, "defining class Class::C fails" );
}

class Class::E {
    method foo { 'Class::E::foo' }
    method zot { 'Class::E::zot' }
}

{
    ::is( ::exception {
        apply_roles_to Class::E, Role::I;
    }, undef, "resolved with method" );
}

can_ok( Class::E->new, qw(foo bar xxy zot) );

is( Class::E->new->foo, "Class::E::foo", "... got the right &foo method" );
is( Class::E->new->zot, "Class::E::zot", "... got the right &zot method" );
is( Class::E->new->bar, "Role::H::bar",  "... got the right &bar method" );
is( Class::E->new->xxy, "Role::J::xxy",  "... got the right &xxy method" );

TODO: {
    todo_skip 'requires_method() does not exist', 1;
    ok(Role::I->requires_method('foo'), '... Role::I still have the &foo requirement');
}

class Class::D {
    has $foo = mop::internal::instance::get_slot_at(Class::D(), '$name') . "::foo"; # is => "rw"
    method foo {
        local $TODO = '$class->get_name does not seem to work at line 200';
        ok(0, 'Dummy test to make the TODO work...');
        $foo
    }
    method zot { 'Class::D::zot' }
}

{
    is( exception {
        apply_roles_to Class::D, Role::I;
    }, undef, "resolved with attr" );

    can_ok( Class::D->new, qw(foo bar xxy zot) );
    is( eval { Class::D->new->bar }, "Role::H::bar", "bar" );
    is( eval { Class::D->new->zzy }, "Role::I::zzy", "zzy" );

    is( eval { Class::D->new->foo }, "Class::D::foo", "foo" );
    is( eval { Class::D->new->zot }, "Class::D::zot", "zot" );

}

done_testing;
