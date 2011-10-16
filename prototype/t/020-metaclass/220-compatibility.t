#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

=pod

Metaclass compatibility is essentially just the concept that an empty subclass
of an existing class should behave identically to the original class (other
than having a different name). In most object systems, this is trivially true,
but when you can declare metaclasses that should be used to construct the
classes, you have to ensure that those metaclasses behave in the same way in
order for this invariant to hold.

The basic algorithm used is that the metaclass used to construct a class must
be either the same as or a subclass of the metaclass used for its superclass.
If this doesn't hold, an exception will be thrown.

This doesn't quite get us to our goal of allowing an empty subclass to behave
identically to its parent, because now if the parent uses a custom metaclass,
you can't create an empty subclass without explicitly specifying the same
metaclass (or else it will die). The second step is that when deciding what
metaclass to use, we also have to look at what superclass was specified. If
that superclass's metaclass is a subclass of the metaclass we are currently
using, we can just instead use the superclass's metaclass directly, since this
won't lose any behavior that was requested in the subclass. This allows

  class FooMeta => (extends   => $::Class) { }
  class Foo     => (metaclass => FooMeta)  { }
  class FooSub  => (extends   => Foo)      { }

to just work.

=cut

BEGIN {
    # create a meta-class (class to create classes with)
    class 'FooMeta' => (extends => $::Class) => sub { };
}

BEGIN {
    # create a class (using our meta-class)
    class 'Foo' => (metaclass => FooMeta) => sub { };
}

is Foo->class, FooMeta, '... got the class we expected';
ok Foo->is_a( FooMeta ), '... Foo is a FooMeta';

BEGIN {
    class 'FooSub' => (extends => Foo) => sub { };
}

is FooSub->class, FooMeta, '... got the class we expected';
ok FooSub->is_a( FooMeta ), '... FooSub is a FooMeta';

BEGIN {
    class 'BarMeta' => (extends => $::Class) => sub { };
}

like exception { class 'BarSub' => (extends => Foo, metaclass => BarMeta) => sub { } },
     qr/While creating class BarSub: Metaclass BarMeta is not compatible with the metaclass of its superclasses: FooMeta/,
     '... incompatible metaclasses die';

done_testing;
