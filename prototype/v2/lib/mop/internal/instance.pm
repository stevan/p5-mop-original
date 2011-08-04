package mop::internal::instance;

use strict;
use warnings;

use Data::UUID;

my $UUID = Data::UUID->new;

sub create {
    my ($class, $data) = @_;
    bless {
        uuid  => $UUID->create_str,
        class => $class,
        data  => $data
    } => 'mop::dispatchable';
}

sub get_uuid  { (shift)->{'uuid'}     }
sub get_class { ${(shift)->{'class'}} }
sub get_data  { (shift)->{'data'}     }
sub get_data_at {
    my ($instance, $name) = @_;
    ${ $instance->{'data'}->{ $name } || \undef }
}

1;

__END__

=pod

=head1 NAME

mop::internal::instance

=head1 DESCRIPTION

This is the low-level instance data structure, it should not be
confused with the Instance Meta Protocol, which will be defined
later on.

There are basically three fields in an instance structure.

The first is a unique identifier. I am using Data::UUID here so that
we can be sure the value will be unique accross processes, threads
and machines. I think this is important for any modern object system
that is to be built within a networked world.

The second is a reference to the Class object that this instance
is connected too.

The third is the structure to hold the actual instance data itself.
This is a HASH ref in which all the keys are references as well. This
data structure is compatible with what PadWalker::set_closed_over
expects for arguments. The reason being that in every method call
we use this data structure as the lexical pad for that method. This
will be explained more further down.

It should also be noted that we bless our instances into the
'mop::dispatchable' package, which is done mostly to make the
prototype function correctly, although the 'mop::dispatchable'
does have use beyond just the prototype (see below).

=head1 TODO

I think that get_data_at needs some re-thinking to improve how
we handle missing data, perhaps an exception.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut