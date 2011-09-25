package mop::internal::instance;

use strict;
use warnings;

use Data::UUID;

my $UUID = Data::UUID->new;

sub create {
    my ($class, $slots) = @_;
    return +{
        uuid  => $UUID->create_str,
        class => $class,
        slots => $slots
    }
}

sub get_uuid  { (shift)->{'uuid'}     }
sub get_class { ${(shift)->{'class'}} }
sub get_slot  { (shift)->{'slots'}    }

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

mop::internal::instance

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut