package mop::internal::attribute::set;

use strict;
use warnings;

use mop::internal::attribute;

sub create {
    my @attributes = @_;
    return +{
        map {
            (mop::internal::attribute::get_name( $_ ) => $_)
        } @attributes
    };
}

sub members {
    my $set = shift;
    values %$set;
}

sub insert {
    my ($set, $attribute) = @_;
    $set->{ mop::internal::attribute::get_name( $attribute ) } = $attribute;
}

sub clone { create( members( @_ ) ) }

1;

__END__

=pod

=head1 NAME

mop::internal::attribute::set

=head1 DESCRIPTION

This is the main module for the mop, it handles the intial
bootstrapping and exporting of the syntactic sugar.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut