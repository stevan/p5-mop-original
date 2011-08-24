package mop::internal::method;

use strict;
use warnings;

use mop::internal::instance;

use PadWalker ();

sub create {
    my %params = @_;

    return +{
        name             => $params{'name'},
        body             => $params{'body'},
        associated_class => $params{'associated_class'}
    }
}

sub associate_class {
    my ($method, $class) = @_;
    $method->{'associated_class'} = $class;
}

sub execute {
    my $method   = shift;
    my $invocant = shift;
    my $class    = mop::internal::instance::get_class( $invocant );
    my $instance = mop::internal::instance::get_data( $invocant );

    PadWalker::set_closed_over( $method->{'body'}, {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class
    });

    # localize the global invocant
    # and class variables here
    local $::SELF  = $invocant;
    local $::CLASS = $class;

    $method->{'body'}->( @_ );
}

1;

__END__

=pod

=head1 NAME

mop::internal::method

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut