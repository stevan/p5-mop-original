package mop;

use strict;
use warnings;

BEGIN {
    # These are global variables of the current invocant
    # and current class of the invocant, they are localized
    # within the body of the current method being executed.
    # These are needed mostly in the bootstrap process so
    # that the class Class and class Object can have access
    # to them.
    $::SELF  = undef;
    $::CLASS = undef;

    # These are global variable that will (post-bootstrap)
    # represent the class Class and class Object respectively.
    # These are populated in the bootstrap process, but are
    # referenced in the syntax modules.
    $::Class  = undef;
    $::Object = undef;

    # these are some of the classes that are also created
    # in the bootstrap and are part of the MOP
    $::Method    = undef;
    $::Attribute = undef;
}

use mop::bootstrap;
use mop::syntax;

use Devel::CallParser;
BEGIN {
    XSLoader::load();
}

mop::bootstrap::init();

sub import { mop::syntax->setup_for( caller ) }

1;

__END__

=pod

=head1 NAME

mop

=head1 DESCRIPTION

This is the main module for the mop, it handles the intial
bootstrapping and exporting of the syntactic sugar.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut