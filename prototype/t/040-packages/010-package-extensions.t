#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This test is kind of experimental, it is
based on the ideas in the Newspeak language
(L<http://newspeaklanguage.org/>) where they
have have a concept of "nested classes" or
sometimes called "modules as objects"
(L<http://bracha.org/newspeak-modules.pdf>).

These concepts and these papers can get
very complex and a little weird, but a
central idea that is found in this is the
ability to enclose a set of classes into
a "module" which itself can be extended
just like a class can. By doing this it
becomes possible to dynamically override
one or more of the classes available in
the module.

This test illustrates that idea in that
it Foo::Extended extends Foo and gets
the Foo::Bar class, but creates its own
Baz class.

=cut

{
    package Foo;

    use strict;
    use warnings;
    use mop;

    class Bar {
        method baz { 'Foo::Bar::baz' }
    }

    class Baz {
        method gorch { 'Foo::Baz::gorch' }
    }
}

{
    my $bar = Foo::Bar->new;
    ok( $bar->isa( Foo::Bar ), '... the object is from class Foo::Bar' );
    is( $bar->baz, 'Foo::Bar::baz', '... go the value expected' );

    my $baz = Foo::Baz->new;
    ok( $baz->isa( Foo::Baz ), '... the object is from class Foo::Baz' );
    is( $baz->gorch, 'Foo::Baz::gorch', '... go the value expected' );
}

{
    package Foo::Extended;

    use strict;
    use warnings;
    use mop;

    use base 'Foo';

    # NOTE:
    # make sure to inherit from the
    # Baz in the parent, this is a
    # nice generic way to do this.
    class Baz (extends => __PACKAGE__->SUPER::Baz) {

        method gorch { 'Foo::Extended::Baz::gorch' }

        # NOTE:
        # can also easily make sure to use the
        # class from the previously derived
        # package as well.
        method bar { __PACKAGE__->Bar->new( @_ ) }
    };
}

{
    my $bar = Foo::Extended->Bar->new;
    ok( $bar->isa( Foo::Bar ), '... the object is from class Foo::Bar' );
    is( $bar->baz, 'Foo::Bar::baz', '... go the value expected' );

    my $baz = Foo::Extended->Baz->new;
    ok( $baz->isa( Foo::Extended::Baz ), '... the object is from class Foo::Baz' );
    ok( $baz->isa( Foo::Baz ), '... the object is from class Foo::Baz' );
    is( $baz->gorch, 'Foo::Extended::Baz::gorch', '... go the value expected' );

    {
        my $bar = $baz->bar;
        ok( $bar->isa( Foo::Bar ), '... the object is from class Foo::Bar' );
        is( $bar->baz, 'Foo::Bar::baz', '... go the value expected' );
    }
}


done_testing;
