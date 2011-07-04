
# Perl 5 MOP

**NOTE: This is still _VERY_ much a work in progress**

This is proposal for a Meta Object Protocol (MOP) for Perl 5.
The main goal of this MOP is to provide a consistent way to
capture and query class metadata. In the spirit of TIMTOWTDI,
this aims to be reasonably un-opinionated so that it can serve
as a shared foundation for various object systems on the CPAN,
now and in the future.

## High Level Overview

This section aims to describe in broad strokes what would make
up a bare bones MOP.

A foundation should support, at a minimum, the following features:

- a way to query and alter the superclass list
    - in desired MRO order
- a way to define and query methods
    - in local class
    - as a union of all inherited methods
- a way to define and query attributes
    - in local class
    - as a union of all inherited attributes

From these features we can build three meta-protocols:

- Class protocol
- Method protocol
- Attribute protocol

Each of which will have a corresponding set of meta-objects
which can be accessed via the MOP.

NOTE: It is the experience of the Moose developers that these
three distinct and largely decoupled protocols are key to
providing a highly extensibility MOP.

## Syntax Extensions

While not strictly neccessary, but in the interest of backwards
compatability, some simple syntax extensions could be made to
Perl 5 to better support the collection of class metadata.

This will also serve as a division line between the old style
Perl 5 classes and these new MOP style classes, which (as we
describe later on) will help with interoperability between these
two styles.

The proposed keywords are:

- class <NAME> { ... }

This is needed to differentiate a class from a regular package.
Additionally, the other keywords (`method`, `has`) will only be valid
within the class block, therefore alleviating the need for a
"use feature" style import mechanism.

The `class` keyword also needs to support a mechanism for inheritance,
though in the interest of extensibility this proposal instead adds
a more general class-metadata capturing mechanism which itself can be
used to implement inheritance (or roles, etc). The syntax would look
like this:

```
  class <NAME> ( <class-metadata> ) { ... }
```

With the parentheses capturing the results of whatever perl expression
is found within it, and storing it in the class meta-object.

- method <NAME> {}

This is needed to differentiate a method from a regular `sub`, however
beyond that it does no more. But as with the `class` keyword, in the
interest of extensibility, this proposal adds a mechanism for capturing
method metadata as well. This is not parameter parsing, but instead
is a means by which parameter parsing might be accomplished. The syntax
would look like this:

```
  method <NAME> ( <method-metadata> ) {}
```

Again, as with the `class` keyword, the parentheses capturing the results
of whatever perl expression is found within it, and storing it in the
corresponding method meta-object.

- has <NAME> ( <attribute-metadata> );

And finally, this is needed to declare an attribute for a class, along
with optional metadata (the same as with `method` and `classes`), which
will be stored in a corresponding attribute meta-object.

## Accessing the MOP

There needs to be a clean simple way to access the meta-objects
for each class and to then use the MOP they implement.

Within a class, access the class meta-object would be through
the __MOP__ keyword (which behaves similar to how __PACKAGE__
behaves in regular packages). Outside of the class you would
need to access the mop in another way, here are a few
proposals:

- new ^ sigil

```
  ^Foo->get_all_methods
  ^{"Foo"}->get_all_methods
```

- new 'mop($)' built-in function

```
  mop("Foo")->get_all_methods
```

- new core "mop" pragma (similar to strict, etc)

```
  mop::get_metaclass("Foo")->get_all_methods
```

Whichever method is chosen it should simply return the class
meta-object corresponding to the class name that is passed as
the argument.

## Event Binding

In addition to accessing the meta-objects in the MOP, there is
also a need to bind to certain MOP events, specifically the
end of the compile-time and the end of the runtime-time.

```
  mop::bind_to_end_of_compile_event( sub { ... } );
  mop::bind_to_end_of_runtime_event( sub { ... } );
```

The end of the compile-time event would fire once the compiler
had finished parsing all the syntax elements and creating the
MOP meta-objects. This would be the time when you might inject
some code into a CV to implement method parsing, or generate
some accessors based on information in the attribute meta-object.

The end of the runtime event would fire once the body of the
class was finished executing, essentially an end of scope hook
for the class block.

## The MOP

The MOP should be made up of 3 interacting classes, one for
each of the protocols. These would be:

- Class

This is the class meta-object, it provides a way to introspect
simple things like the name and version of the class. It also
provides read and write access to the superclass list (which is
mostly delegated to the existing mro functionality). It also
contains a set of attribute meta-objects and a set of method
meta-objects, and ways to alter those sets.

It also is where you will go to access the class metadata that
is captured by the syntax described above.

NOTE: When I say 'set' I mean the set data structure, such as
what is found in a module like Set::Object.

- Method

This is a method meta-object, it provides simple introspection
of things like the name of the method and a pointer to the
underlying CV data structure. And as with the class meta-object
this is where you would access the method metadata that is
captured with the syntax described above.

- Attribute

This is the attribute meta-object and since there is not direct
correspondence in Perl 5 already, this pretty much just captures
the name and metadata using the syntax described above.

The exact APIs of each of these meta-objects is not described
(yet) by this document, but will be forthcoming in future versions.

### Interacting with old style classes

It is critically important that these new style classes interact
well with old style Perl 5 classes. The simplest way to do that
is for there to also be a set of meta-objects that work with
old style classes. These meta-objects would attempt to provide
the same API (minus the Attribute since it does not exist in
old style classes) so that the MOP can interact with both in a
seemless manner. This is also how existing object systems like
Moose could be made to work with this new MOP.

## Using the MOP

Here are a few examples (with many more to come), of how the MOP
could be used.

### Generating Object Instances

The main responsibility of a class is to generate instances, so it
should be fairly easy to build an instance of a class using the MOP.

Here is a simple example of a MOP powered constructor:

```
  class Point {
      has x;
      has y;

      method new {
          my ($class, %args) = @_;
          bless({
              map {
                $_->name => ($args{ $_->name } || undef)
              } __MOP__->get_all_attributes),
          }, $class);
      }
  }
```

### Building Moose on top of the MOP

Okay, just to prove a point, here is a quick example of how we might be
able to implement a Moose-like system taking advantage of the new syntax.

```
  class Point {
      use Moose 3.0;

      has x ( is => 'ro', isa => 'Int', default => 0 );
      has y ( is => 'ro', isa => 'Int', default => 0 );

      method clear {
          my ($self) = @_;
          $self->x(0);
          $self->y(0);
      }
  }

  class Point3D ( extends => Point ) {
      use Moose 3.0;

      has z ( is => 'ro', isa => 'Int' );

      after clear => method {
          my $self = shift;
          $self->z(0);
      };
  }
```

## The End

Or is it ... dah dah dum!


