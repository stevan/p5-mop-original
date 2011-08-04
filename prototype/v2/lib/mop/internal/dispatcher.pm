package mop::internal::dispatcher;

use strict;
use warnings;

use mop::internal::instance;

use PadWalker ();

sub WALKMETH {
    my ($class, $method_name, %opts) = @_;
    WALKCLASS(
        $class,
        # FIXME:
        # We really should have a internal::class
        # module which handles finding a method
        # by name. This actually only needs to be
        # so low leve for $Class, the other class
        # objects can call methods.
        # - SL
        sub { mop::internal::instance::get_data_at( $_[0], '$methods' )->{ $method_name } },
        %opts
    );
}

sub WALKCLASS {
    my ($class, $solver, %opts) = @_;
    unless ( delete $opts{'super'} ) {
        if ( my $result = $solver->( $class ) ) {
            return $result;
        }
    }
    # FIXME:
    # this actually should be checking the
    # MRO and not the superclass list. But
    # as stated above, this is only really
    # needed for $Class, the other classes
    # can actually call methods.
    # - SL
    foreach my $super ( @{ mop::internal::instance::get_data_at( $class, '$superclasses' ) } ) {
        if ( my $result = WALKCLASS( $super, $solver, %opts ) ) {
            return $result;
        }
    }
}

sub CALLMETHOD {
    my $method   = shift;
    my $invocant = shift;
    my $class    = mop::internal::instance::get_class( $invocant );
    my $instance = mop::internal::instance::get_data( $invocant );

    PadWalker::set_closed_over( $method, {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class
    });

    # FIXME:
    # these are just aliasing
    # globals, and we need a
    # better way to handle this
    # perhaps mop.pm should
    # take care of this kind
    # of stuff.
    # - SL
    local $::SELF  = $invocant;
    local $::CLASS = $class;

    $method->( @_ );
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