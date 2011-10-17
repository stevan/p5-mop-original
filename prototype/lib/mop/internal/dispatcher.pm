package mop::internal::dispatcher;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;
use mop::internal::method;

=pod

This module should be able to give you an
optimizer vtable for a given class.

=cut

sub WALKMETH {
    my ($class, $method_name, %opts) = @_;
    WALKCLASS(
        $class,
        sub { mop::internal::class::find_method( $_[0], $method_name ) },
        %opts
    );
}

sub WALKCLASS {
    my ($class, $solver, %opts) = @_;
    my @mro = @{ mop::internal::class::get_mro( $class ) };
    shift @mro if exists $opts{'super'};
    @mro = reverse @mro if $opts{'reverse'};
    foreach my $_class ( @mro ) {
        if ( my $result = $solver->( $_class ) ) {
            return $result;
        }
    }
    return;
}

sub DISPATCH {
    my $method_name = shift;
    my $invocant    = shift;
    my $class       = mop::internal::instance::get_class( $invocant );
    my $method = WALKMETH(
        $class,
        $method_name
    ) || die "Could not find method '$method_name' in class(" . mop::internal::instance::get_slot_at( $class, '$name' ) . ")";
    CALLMETHOD( $method, $invocant, @_ );
}

sub SUBDISPATCH {
    my $find_method = shift;
    my $reverse     = shift;
    my $invocant    = shift;
    my @args        = @_;
    my $class       = mop::internal::instance::get_class( $invocant );

    $find_method = sub { mop::internal::class::find_method( $_[0], $find_method ) }
        if !ref($find_method);

    WALKCLASS(
        $class,
        sub {
            my $method = $find_method->( $_[0] );
            CALLMETHOD( $method, $invocant, @args ) if $method;
            return;
        },
        reverse => $reverse,
    );
}

sub NEXTMETHOD {
    my $method_name = shift;
    my $invocant    = shift;
    my $method      = WALKMETH(
        mop::internal::instance::get_class( $invocant ),
        $method_name,
        (super => 1)
    ) || die "Could not find method '$method_name'";
    CALLMETHOD( $method, $invocant, @_ );
}

sub CALLMETHOD {
    my $method   = shift;
    my $invocant = shift;
    mop::internal::method::execute( $method, $invocant, @_ );
}

1;

__END__

=pod

=head1 NAME

mop::internal::dispatcher

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut