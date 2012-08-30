#!perl
use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

=pod

class Foo ( extends => Bar ) {

    # without block
    meta ( extends => MetaFoo, with => [ Foo, Bar ] );

    # with block
    meta ( with => [ Foo, Bar ] ) {

        method attribute_metaclass { SomeRandomAttribute }

        has $foo;
        method BUILDARGS ($params) {
            # ...
        }
    }

}

# desugars to

class Foo ( metaclass => class ( extends => $::Class ) {
        method BUILDARGS ($params) {
            # ...
        }
    }) {

    # ...
}


=cut

local $TODO = "not yet implemented";
fail;

done_testing;
