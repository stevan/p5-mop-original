package mop::internal::class;

use strict;
use warnings;

use mop::internal::instance;

sub create {
    my %params = @_;

    my $superclasses = $params{'superclasses'} || [];
    my $attributes   = $params{'attributes'}   || {};
    my $methods      = $params{'methods'}      || {};

    mop::internal::instance::create(
        \$::Class,
        {
            '$superclasses' => \$superclasses,
            '$attributes'   => \$attributes,
            '$methods'      => \$methods
        }
    );
}

sub get_superclasses { mop::internal::instance::get_data_at( $_[0], '$superclasses' ) }
sub get_methods      { mop::internal::instance::get_data_at( $_[0], '$methods' )      }
sub get_attributes   { mop::internal::instance::get_data_at( $_[0], '$attributes' )   }

sub get_mro {
    my $class = shift;
    return [
        $class,
        map { @{ get_mro( $_ ) } } @{ get_superclasses( $class ) }
    ]
}

sub find_method {
    my ($class, $method_name) = @_;
    get_methods( $class )->{ $method_name }
}

1;

__END__

=pod

=head1 NAME

mop::internal::class

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut