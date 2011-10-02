#!perl

use strict;
use warnings;

use Test::More;

use mop;

BEGIN {

    # FIXME:
    # we should be able to import
    # these, but exactly how is
    # currently escaping me.
    # - SL
    my ($self, $class);

    class 'Point' => sub {
        has( my $x ) = 0;
        has( my $y ) = 0;

        method 'x' => sub { $x };
        method 'y' => sub { $y };

        method 'set_x' => sub {
            my $new_x = shift;
            $x = $new_x;
        };

        method 'clear' => sub {
            ($x, $y) = (0, 0);
        };

        method 'dump' => sub {
            +{ x => $self->x, y => $self->y }
        };
    };

    # ... subclass it ...

    class 'Point3D' => sub {
        extends Point();

        has( my $z ) = 0;

        method 'z' => sub { $z };

        method 'dump' => sub {
            my $orig = $self->NEXTMETHOD('dump');
            $orig->{'z'} = $z;
            $orig;
        };
    };

}

## Test the class

like Point->id, qr/[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}/i, '... got the expected uuid format';
is Point->class, $::Class, '... got the class we expected';
ok Point->is_a( $::Object ), '... class Point is a Object';
ok Point->is_subclass_of( $::Object ), '... class Point is a subclass of Object';
is_deeply Point->get_superclasses, [ $::Object ], '... got the superclasses we expected';
is_deeply Point->get_mro, [ Point, $::Object ], '... got the mro we expected';
is_deeply
    [ sort { $a cmp $b } map { $_->get_name } values %{ Point->get_attributes } ],
    [ '$x', '$y' ],
    '... got the superclasses we expected';

## Test an instance

my $p = Point->new( x => 100, y => 320 );
ok $p->is_a( Point ), '... p is a Point';

like $p->id, qr/[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}/i, '... got the expected uuid format';
is $p->class, Point, '... got the class we expected';

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

my $p2 = Point->new( x => 1, y => 30 );

isnt $p->id, $p2->id, '... not the same instances';

is $p2->x, 1, '... got the right value for x';
is $p2->y, 30, '... got the right value for y';
is_deeply $p2->dump, { x => 1, y => 30 }, '... got the right value from dump';

$p2->set_x(500);
is $p2->x, 500, '... got the right value for x';
is_deeply $p2->dump, { x => 500, y => 30 }, '... got the right value from dump';

is $p->x, 10, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

$p->clear;
is $p->x, 0, '... got the right value for x';
is $p->y, 0, '... got the right value for y';
is_deeply $p->dump, { x => 0, y => 0 }, '... got the right value from dump';

## Test the subclass

is Point3D->class, $::Class, '... got the class we expected';
ok Point3D->is_a( $::Object ), '... class Point3D is a Object';
ok Point3D->is_subclass_of( Point ), '... class Point3D is a subclass of Point';
ok Point3D->is_subclass_of( $::Object ), '... class Point3D is a subclass of Object';
is_deeply Point3D->get_superclasses, [ Point ], '... got the superclasses we expected';
is_deeply Point3D->get_mro, [ Point3D, Point, $::Object ], '... got the mro we expected';
is_deeply
    [ map { $_->get_name } values %{ Point3D->get_attributes } ],
    [ '$z' ],
    '... got the superclasses we expected';


## Test the instance

my $p3d = Point3D->new( x => 1, y => 2, z => 3 );
ok $p3d->is_a( Point3D ), '... p3d is a Point3D';
ok $p3d->is_a( Point ), '... p3d is a Point';

is $p3d->x, 1, '... got the right value for x';
is $p3d->y, 2, '... got the right value for y';
is $p3d->z, 3, '... got the right value for z';

is_deeply $p3d->dump, { x => 1, y => 2, z => 3 }, '... go the right value from dump';

## test the default values

{
    my $p = Point->new;
    is_deeply $p->dump, { x => 0, y => 0 }, '... go the right value from dump';

    my $p3d = Point3D->new;
    is_deeply $p3d->dump, { x => 0, y => 0, z => 0 }, '... go the right value from dump';
}

done_testing;



