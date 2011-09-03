package mop::internal::attribute;

use strict;
use warnings;

use Scalar::Util ();
use Clone        ();

sub create {
    my %params = @_;

    return +{
        name             => $params{'name'},
        initial_value    => $params{'initial_value'},
        associated_class => $params{'associated_class'}
    }
}

sub get_name             { $_[0]->{'name'} }
sub get_initial_value    { $_[0]->{'initial_value'} }
sub get_associated_class { $_[0]->{'associated_class'} }

sub associate_with_class {
    my ($attr, $class) = @_;
    $attr->{'associated_class'} = $class;
}

sub get_initial_value_for_instance {
    my $attr = shift;
    my $value = ${ $attr->{'initial_value'} };
    if ( Scalar::Util::blessed( $value ) ) {
        if ( $value->can('clone') ) {
            $value = $value->clone;
        }
        else {
            die "Cannot clone $value";
        }
    }
    else {
        $value = Clone::clone( $value ) if ref $value;
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