package mop::internal;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use overload ();
use Package::Anon;
use PadWalker qw(set_closed_over);
use Scalar::Util qw(refaddr weaken);
use Scope::Guard qw(guard);

use mop::internal::instance qw(get_uuid get_class get_slots get_slot_at);
use mop::util;

use Exporter 'import';
our @EXPORT_OK = qw(get_stash_for apply_overloading_for_stash);

sub get_stash_for {
    state $VTABLES = {};
    my $class = shift;
    $VTABLES->{ get_uuid($class) } //= _create_stash_for( $class );
}

sub apply_overloading_for_stash {
    my ($stash) = @_;

    # enable overloading
    {
        no strict 'refs';
        local *__ANON__ = $stash;
        *{ "__ANON__::OVERLOAD" }{HASH}->{dummy}++;
    }
    $stash->add_method('()' => \&overload::nil);

    # fallback => 1
    *{ $stash->{'()'} } = \1;

    # overloaded operations
    $stash->add_method('(bool' => sub { 1 });
    $stash->add_method('(~~' => sub {
        my $self = shift;
        my ($other) = @_;
        return $other->DOES($self);
    });
    $stash->add_method('(""' => sub { overload::StrVal($_[0]) });
    $stash->add_method('(0+' => sub { refaddr($_[0]) });
    $stash->add_method('(==' => sub { get_uuid($_[0]) eq get_uuid($_[1]) });
}

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

# XXX used by FINALIZE, but moved here because we need to hardcode some things
# that FINALIZE does when bootstrapping... find a better way to do this maybe?
sub generate_DESTROY {
    return sub {
        my $invocant = shift;

        my $class = get_class( $invocant );
        return unless $class; # likely in global destruction ...

        mop::util::WALKCLASS(
            $class->dispatcher(),
            sub {
                my $dispatcher = $_[0]->destructor;
                return unless $dispatcher;
                $dispatcher->execute($invocant);
                return;
            }
        );
    }
}

sub _create_stash_for {
    my ($class) = @_;
    my $stash = Package::Anon->new(${ get_slot_at( $class, '$name' ) } || ());
    apply_overloading_for_stash($stash);
    return $stash;
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