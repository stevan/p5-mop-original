package mop;

use strict;
use warnings;

use mop::internal::instance;
use mop::internal::dispatcher;

{
    # NOTE:
    # The exact implementation of this is heavily tied to the prototype
    # and making the prototype behave as expected on the user language
    # level.

    # Specifically, we are using AUTOLOAD here as a general purpose
    # dispatching mechanism. This is simply a means of making the
    # prototype work, it should not be seen as a recommendation for
    # the actual implementation.

    package mop::dispatchable;
    use strict;
    use warnings;

    sub NEXTMETHOD {
        my $invocant    = shift;
        my $method_name = shift;
        mop::internal::dispatcher::NEXTMETHOD( $method_name, $invocant, @_ );
    }

    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        mop::internal::dispatcher::DISPATCH( $method_name, @_ );
    }
}

1;

__END__

=pod

=head1 NAME

mop

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut