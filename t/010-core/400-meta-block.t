#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

=pod

class Foo ( extends => Bar ) {

    meta ( extends => MetaFoo, with => [ Foo, Bar ] );

    meta ( with => [ Foo, Bar ] ) {

        method attribute_metaclass { SomeRandomAttribute }

        has $foo;
        method BUILDARGS {
            ...
        }
    }
}

=cut

done_testing;