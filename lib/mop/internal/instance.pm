package mop::internal::instance;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Exporter 'import';
our @EXPORT_OK = qw(
    create_instance
    get_uuid get_class get_slots
    set_class
    get_slot_at set_slot_at
);

1;

__END__

=pod

=head1 NAME

mop::internal::instance - The p5-mop instance internals

=head1 DESCRIPTION

This module implements an instance type for the p5-mop.

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
