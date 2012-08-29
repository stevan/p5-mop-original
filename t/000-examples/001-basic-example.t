#!perl

use strict;
use warnings;

use Test::More;

use mop;

class Point {
    has $x = 0;
    has $y = 0;

    method x { $x }
    method y { $y }

    method set_x ($new_x) {
        $x = $new_x;
    }

    method clear {
        ($x, $y) = (0, 0);
    }

    method dump {
        +{ x => $self->x, y => $self->y }
    }
}

# ... subclass it ...

class Point3D (extends => Point) {
    has $z = 0;

    method z { $z }

    method dump {
        my $orig = super;
        $orig->{'z'} = $z;
        $orig;
    }
}

class Point4D (extends => Point3D) {
    has $t = 0;

    method t { $t }

    method dump {
        my $orig = super;
        $orig->{'t'} = $t;
        $orig;
    }
}

my $Object = Point->get_superclass;

sub main::_name ($) { mop::internal::instance::get_slot_at(shift, '$name') }

$::DEBUG = 1;
warn _name($_) . ": " . $_
    for $Object, Point, Point3D, Point4D;


#is_deeply (
#    [ map { _name($_) } $Object->get_mro ],
#    [ $Object ],
#);
#
#is_deeply (
#    [ map { _name($_) } Point->get_mro ],
#    [ Point, $Object ],
#);
#
is_deeply (
    [ map { _name($_) } Point3D->get_mro ],
    [ Point3D, Point, $Object ],
);

#is_deeply (
#    Point4D->get_mro,
#    [ Point4D, Point3D, Point, $Object ],
#);

for my $invocant (($Object, Point, Point3D, Point4D)[0]) {
    warn _name($_) . "->get_mro: ";
    warn "    " . join ', ', map { _name($_) } @{ $invocant->get_mro };
}

$::DEBUG = 0;

done_testing;

