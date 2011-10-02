#!perl

use strict;
use warnings;

use Test::More;

use mop;

=pod

Since attributes are viewed as
lexically scoped variables, it
is possible to overwrite the
name (which is dumb, but you
can do it). And this is fine
as long as the scope doesn't
bleed into other scopes (and
it doesn't).

=cut

BEGIN {
    my ($self, $class);

    class 'Foo' => sub {
        has( my $bar ) = 99;

        method 'bar' => sub { $bar };

        method 'test' => sub {
            my $bar = 'bottles of beer';
            join " " => ( $self->bar, $bar );
        };

    };
}

my $foo = Foo->new;

is( $foo->test, '99 bottles of beer', '... this worked as expected' );

done_testing;



