package mop;

use 5.014;
use strict;
use warnings;

BEGIN {
    our $VERSION   = '0.01';
    our $AUTHORITY = 'cpan:STEVAN';

    # These are global variables of the current invocant
    # and current class of the invocant, they are localized
    # within the body of the current method being executed.
    # These are needed mostly in the bootstrap process so
    # that the class Class and class Object can have access
    # to them.
    $::SELF  = undef;
    $::CLASS = undef;

    # this is the current method being executed it is mostly
    # needed for finding the super-method
    $::CALLER = undef;

    # These are global variable that will (post-bootstrap)
    # represent the class Class and class Object respectively.
    # These are populated in the bootstrap process, but are
    # referenced in the syntax modules.
    $::Class  = undef;
    $::Object = undef;

    # these are some of the classes that are also created
    # in the bootstrap and are part of the MOP
    $::Method        = undef;
    $::Attribute     = undef;
    $::Role          = undef;

    $::HasMethods         = undef;
    $::HasAttributes      = undef;
    $::HasRoles           = undef;
    $::HasName            = undef;
    $::HasVersion         = undef;
    $::HasRequiredMethods = undef;
    $::Composable         = undef;
    $::HasSuperclass      = undef;
    $::Instantiable       = undef;
    $::Dispatchable       = undef;
}

use mop::bootstrap;
use mop::syntax;

use Devel::CallParser;

BEGIN { XSLoader::load(__PACKAGE__, our $VERSION) }

mop::bootstrap::init();

sub import {
    shift;
    my %options = @_;
    $^H{'mop/default_metaclass'} = $options{'-metaclass'}
        if $options{'-metaclass'};
    mop::syntax->setup_for( $options{'-into'} // caller )
}

sub WALKCLASS {
    my ($dispatcher, $solver) = @_;
    { $solver->( $dispatcher->() || return ); redo }
}

sub WALKMETH {
    my ($dispatcher, $method_name) = @_;
    { ( $dispatcher->() || return )->get_local_methods->{ $method_name } || redo }
}

sub class_of ($) { mop::internal::instance::get_class( shift ) }
sub uuid_of  ($) { mop::internal::instance::get_uuid( shift )  }

1;

__END__

=pod

=head1 NAME

mop - The p5-mop

=head1 DESCRIPTION

This is the main module for the mop, it handles the intial
bootstrapping and exporting of the syntactic sugar.

To find out more about this module you will want to look at
L<mop::proposal::intro>.

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 CONTRIBUTORS

The following is a list of people who have contributed to
the development of this module through discussion and/or
encouragement.

Jesse Vincent

Shawn Moore

chromatic

Steffen Mueller

Abigail

Father Chrysostomos

Yuki Kimoto

Nicholas Clark

Reini Urban

Andrew Main (Zefram)

Hugo van der Sanden

Aarron Crane

Vyacheslav Matjukhin

A.Vieth (forwardever)

Dmitry Karasik

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut