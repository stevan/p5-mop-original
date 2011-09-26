package mop::internal::dispatcher;

use strict;
use warnings;

use mop::internal::class;
use mop::internal::instance;
use mop::internal::method;

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
    my $method = WALKMETH(
        mop::internal::instance::get_class( $invocant ),
        $method_name
    ) || die "Could not find method '$method_name'";
    CALLMETHOD( $method, $invocant, @_ );
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