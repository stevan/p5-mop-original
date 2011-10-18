package mop::syntax::dispatchable;

use strict;
use warnings;

use mop::internal::dispatcher;

use MRO::Magic
    metamethod => sub {
        my $invocant = shift;
        my ($method_name, $args) = @_;
        mop::internal::dispatcher::DISPATCH( $method_name, $invocant, @$args );
    },
    passthru => [
        # methods we define here
        'NEXTMETHOD', 'DESTROY',
        # class methods we can't control if they will be called
        'import',
        # for some reason, MRO::Magic breaks keywords used in this package
        'shift', 'caller',
    ];

sub NEXTMETHOD {
    my $invocant    = shift();
    my $method_name = (split '::' => ((caller(1))[3]))[-1];
    mop::internal::dispatcher::NEXTMETHOD( $method_name, $invocant, @_ );
}

sub DESTROY {
    my $invocant = shift();
    mop::internal::dispatcher::SUBDISPATCH(
        sub { mop::internal::class::get_destructor( $_[0] ) },
        0,
        $invocant,
    );
}

1;

__END__

=pod

=head1 NAME

mop::syntax::dispatchable

=head1 DESCRIPTION

The exact implementation of this is heavily tied to the prototype
and making the prototype behave as expected on the user language
level.

Specifically, we are using AUTOLOAD here as a general purpose
dispatching mechanism. This is simply a means of making the
prototype work, it should not be seen as a recommendation for
the actual implementation.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut