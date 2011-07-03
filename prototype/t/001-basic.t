#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

use Test::More;

BEGIN {
    use_ok('mop');
}

class 'Point' => sub {

    has 'x';
    has 'y';

    # YUK!
    my $MOP = __MOP__;

    method 'new' => sub {
        my ($class, %args) = @_;
        bless {
            map {
              $_->name => ($args{ $_->name } || undef)
            } @{ $MOP->attributes }
        } => $class;
    }

};

my $meta = mop::get_metaclass('Point');

warn Dumper $meta;

# YUK!
my $point = $meta->methods->[0]->body->(
    $meta->name,
    x => 10
);

warn Dumper $point;

done_testing;