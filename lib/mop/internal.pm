package mop::internal;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use PadWalker qw(set_closed_over);
use Scalar::Util qw(weaken);
use Scope::Guard qw(guard);

use mop::internal::instance qw(get_uuid get_class get_slots get_slot_at);
use mop::util;

sub execute_method {
    state $STACKS = {};

    my $method   = shift;
    my $invocant = shift;
    weaken($invocant);

    my $uuid     = get_uuid($method);
    my $class    = get_class( $invocant );
    my $instance = get_slots( $invocant );
    my $body     = ${ get_slot_at( $method, '$body' ) };

    my $env      = {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class
    };

    $STACKS->{ $uuid } = []
        unless ref $STACKS->{ $uuid };

    push @{ $STACKS->{ $uuid } } => $env;
    set_closed_over( $body, $env );

    my $g = guard {
        my $stack = $STACKS->{ $uuid };
        pop @$stack;
        my $env = $stack->[-1];
        if ( $env ) {
            set_closed_over( $body, $env );
        }
        else {
            set_closed_over( $body, {
                (map { $_ => mop::util::undef_for_type($_) } keys %$instance),
                '$self'  => \undef,
                '$class' => \undef,
            });
        }
    };

    # localize the global invocant,
    # caller and class variables here
    local $::SELF   = $invocant;
    local $::CLASS  = $class;
    local $::CALLER = $method;

    $body->( @_ );
}

1;

__END__

=pod

=head1 NAME

mop::internal - The internals of the p5-mop

=head1 DESCRIPTION

This module contains some internal functions that
are mostly used in the bootstraping process. It is
here were most of the dragons lie, be not afraid,
this will not be the final implementation.

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut