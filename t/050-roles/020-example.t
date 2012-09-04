#!perl

use strict;
use warnings;

use Test::More;

use mop;

role Eq {
    method equal;

    method not_equal ($other) {
        not $self->equal($other);
    }
}

role Ord (does => [Eq]) {
    method compare;

    method equal ($other) {
        $self->compare($other) == 0;
    }
}

class Point (does => [Eq]) {
    has $x = 0;
    has $y = 0;

    method x { $x }
    method y { $y }

    method equal ($other) {
        $self->x eq $other->x
            and
        $self->y eq $other->y
    }
}

class Point1D (does => [Ord]) { # "Number" ;-)
    has $x = 0;
    method x { $x }

    method compare ($other) {
        $self->x <=> $other->x;
    }
}

## Test the class

ok Point->new->does(Eq), 'class Point does Eq ...';
ok Point->does_role(Eq), 'class Point does Eq ...';
is_deeply [ map { $_->get_name } Point->get_all_roles ], [qw(Eq)], '… got the roles we expected';
ok Point->new->can("equal"), '˙˙˙ implements equal method';
ok Point->find_method("equal"), '˙˙˙ implements equal method';
is_deeply Point->get_mro, [ Point, $::Object ], '⸘⸘⸘ got the mro we expected ‽‽‽';
is_deeply
    [ sort { $a cmp $b } map { $_->get_name } values %{ Point->get_all_methods } ],
    [ sort qw(x y equal not_equal),
           map { $_->get_name } values %{ $::Object->get_all_methods } ],
    ', got , the , attribute , list , we , expected ,';

## Test an instance

my $p1 = Point->new( x => 100, y => 320 );
my $p2 = Point->new( x => 100, y => 320 );
my $p3 = Point->new( x => 100, y => 33 );
ok $_->isa( Point ), '... p is a Point' for $p1, $p2, $p3;


ok $p1->equal($p1), "object equals itself";
ok $p1->equal($p2), "object equals other";
ok !$p1->equal($p3), "object does not equal other";
ok $p1->not_equal($p3), "not_equal role method says the same";

ok Point1D->new->does(Ord), "Point1D does Ord";
ok Point1D->does_role(Ord), "Point1D does Ord";
is_deeply [ map { $_->get_name } Point1D->get_local_roles ], [qw(Ord)], 'directly applied roles';
is_deeply [ sort map { $_->get_name } Point1D->get_all_roles ], [qw(Eq Ord)], 'directly applied roles';

my $n1 = Point1D->new( x => 1 );
my $n2 = Point1D->new( x => 1 );
my $n3 = Point1D->new( x => 3 );

is $n1->compare($n1), 0, "compare with self";
is $n1->compare($n2), 0, "compare with equal";
is $n1->compare($n3), -1, "compare with diff";
is $n3->compare($n2), 1, "compare with diff";

ok $n1->equal($n2), "equal based on compare";
ok $n1->not_equal($n3), "not_equal based on compare";

done_testing;



