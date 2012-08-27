#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;
use Fun;

use lib 't/400-yapc-eu-examples/lib/';

use GuardedAttribute;

class Foo (metaclass => GuardedAttributeClass) {
    has $bar;
    has $baz;
    has $age ( guard => fun ($x) { $x =~ /^\d+$/ } );

    method age { $age }
    method set_age ( $new_age ) {
        $age = $new_age;
    }
}

my $foo = Foo->new;

my $age_attr = Foo->find_attribute('$age');
ok($age_attr->isa( GuardedAttribute ), '... this is a Guarded Attribute');

{
    my $guard = $age_attr->guard;
    ok($guard->( 10 ), '... guard worked as expected');
}

like(exception { $foo->set_age('test') }, qr/^Value \'SCALAR\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');
like(exception { $foo->set_age(\10)    }, qr/^Value \'REF\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');
like(exception { $foo->set_age([])     }, qr/^Value \'REF\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');
like(exception { $foo->set_age({})     }, qr/^Value \'REF\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');

is(exception { $foo->set_age(10) }, undef, '... guard accepted the input');

is($foo->age, 10, '... got the right value');

# metaroles

role Bar (metaclass => GuardedAttributeRole) {
    has $hash ( guard => fun ($x) { ref $x && ref $x eq 'HASH' } );

    method hash { $hash }
    method set_hash ( $new_hash ) {
        $hash = $new_hash;
    }
}

class Baz ( with => Bar ) {}

my $baz = Baz->new;

my $hash_attr = Baz->find_attribute('$hash');
ok($hash_attr->isa( GuardedAttribute ), '... this is a Guarded Attribute');

{
    my $guard = $hash_attr->guard;
    ok($guard->( {} ), '... guard worked as expected');
}

like(exception { $baz->set_hash('test') }, qr/^Value \'SCALAR\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');
like(exception { $baz->set_hash(\10)    }, qr/^Value \'REF\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');
like(exception { $baz->set_hash([])     }, qr/^Value \'REF\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');
like(exception { $baz->set_hash(10)     }, qr/^Value \'SCALAR\(0x[a-z0-9]+\)\' did not pass the guard .*/, '... guard tripped the exception');

is(exception { $baz->set_hash({ foo => 1 }) }, undef, '... guard accepted the input');

is_deeply($baz->hash, { foo => 1 }, '... got the right value');

done_testing;