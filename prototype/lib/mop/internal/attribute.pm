package mop::internal::attribute;

use strict;
use warnings;

use Clone ();

sub create {
    my %params = @_;

    my $name          = $params{'name'}          || die "An attribute must have a name";
    my $initial_value = $params{'initial_value'} || undef;

    mop::internal::instance::create(
        \$::Attribute,
        {
            '$name'          => \$name,
            '$initial_value' => \$initial_value,
        }
    );
}

sub get_initial_value_for_instance {
    my $attr = shift;
    my $value = ${ mop::internal::instance::get_slot_at( $attr, '$initial_value' ) };

    if ( ref $value ) {
        if ( ref $value eq 'ARRAY' || ref $value eq 'HASH' ) {
            $value = Clone::clone( $value );
        }
        elsif ( ref $value eq 'CODE' ) {
            $value = $value->();
        }
        else {
            die "References of type(" . ref $value . ") are not supported";
        }
    }

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