package mop::util;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

sub WALKCLASS {
    my ($dispatcher, $solver) = @_;
    { $solver->( $dispatcher->() || return ); redo }
}

sub WALKMETH {
    my ($dispatcher, $method_name) = @_;
    { ( $dispatcher->() || return )->local_methods->{ $method_name } || redo }
}

sub undef_for_type {
    my ($name) = @_;
    my $sigil = substr($name, 0, 1);
    if ($sigil eq '$') {
        return \undef;
    }
    elsif ($sigil eq '@') {
        return [];
    }
    elsif ($sigil eq '%') {
        return {};
    }
    else {
        die "Unknown sigil '$sigil' for name $name";
    }
}

sub sort_slot_hash {
    my ($slots) = @_;

    return {
        map { $_ => $slots->{$_} } sort keys %{ $slots },
    };
}

1;
