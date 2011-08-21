package mop::internal::attribute;

use strict;
use warnings;

use Clone ();

sub get_initial_value {
    my $attr = shift;
    my $value = ${ $attr };
    $value = Clone::clone( $value ) if ref $value;
    return \$value;
}

1;

__END__

=pod

=head1 NAME

mop::internal::attribute

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut