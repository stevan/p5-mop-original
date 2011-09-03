package mop::internal::util::set;

use strict;
use warnings;

sub create {
    my @members = @_;
    return +{ map { ("$_" => $_) } @members };
}

sub members {
    my $set = shift;
    values %$set;
}

sub insert {
    my ($set, $item) = @_;
    $set->{ "$item" } = $item;
}

sub clone { create( members( @_ ) ) }

1;

__END__

=pod

=head1 NAME

mop::internal::util::set

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