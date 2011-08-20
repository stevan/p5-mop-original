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

=head1 DESCRIPTION

The real useful parts of the dispatcher are the three methods;
WALKMETH, WALKCLASS and DISPATCH. These were somewhat borrowed
from Perl 6, but with some modifications. Each one has a specific
set of responsibilities.

WALKMETH is primarliy responsible for finding a method within a
given class. This means that it must know enough about a Class
object to be able to find a method within it.

WALKCLASS is primarily responsible for traversing the MRO of
a Class object and applying a $solver callback to each class
until the callback returns something.

CALLMETHOD is concerned with setting up a method to be executed.
This means setting up the lexical environment for the method and
then executing the method.

DISPATCH is concerned with finding the method, after which it
will call CALLMETHOD to execute it.

NEXTMETHOD is actually kind of in between DISPATCH and
the AUTOLOAD handler. It is actually treated as a method
by the instances, and given a method name it will call the
superclass method (if there is one) for that method. It
should be noted that this is not a recommendation for how
to implement such a feature, it is simply here to show behavior
and nothing more.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut