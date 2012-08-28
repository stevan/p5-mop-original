package mop::internal::instance;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use UUID::Tiny qw[ create_uuid_as_string UUID_V4 ];

sub create {
    my ($class, $slots) = @_;
    return +{
        uuid  => create_uuid_as_string(UUID_V4),
        class => $class,
        slots => $slots
    }
}

sub get_uuid  { (shift)->{'uuid'}     }
sub get_class { ${(shift)->{'class'}} }
sub get_slots { (shift)->{'slots'}    }

sub set_class {
    my ($instance, $class) = @_;
    $instance->{'class'} = \$class;
}

sub get_slot_at {
    my ($instance, $name) = @_;
    ${ $instance->{'slots'}->{ $name } || \undef }
}

sub set_slot_at {
    my ($instance, $name, $value) = @_;
    $instance->{'slots'}->{ $name } = $value
}

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
