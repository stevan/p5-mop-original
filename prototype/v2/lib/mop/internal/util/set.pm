package mop::internal::util::set;

use strict;
use warnings;

use Set::Object ();

sub create { Set::Object->new( @_ ) }

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