#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/ext/Class-MOPX';

use Class::MOPX;

use Scalar::Util 'weaken';

class Foo {
    has $foo;
    method foo { $foo }
}

{
    my $attr = Foo->find_attribute('$foo');
    my $method = Foo->find_method('foo');

    isa_ok($attr->associated_class, Class::MOPX::Class);
    isa_ok($method->associated_class, Class::MOPX::Class);

    weaken(my $class = Foo);
    is($class, Foo);

    undef *Foo;

    { local $TODO = "we're too leaky for this to work at the moment"
    is($attr->associated_class, undef);
    is($method->associated_class, undef);
    is($class, undef);
    }
}

done_testing;
