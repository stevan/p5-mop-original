package mop::internal::method::set;

use strict;
use warnings;

use mop::internal::method;

sub create {
    my @methods = @_;
    return +{
        methods => {
            map {
                (mop::internal::method::get_name( $_ ) => $_)
            } @methods
        }
    };
}

sub members {
    my $set = shift;
    values %{ $set->{'methods'} };
}

sub insert {
    my ($set, $method) = @_;
    $set->{'methods'}->{ mop::internal::method::get_name( $method ) } = $method;
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