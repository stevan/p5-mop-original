package mop::full;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Module::Runtime 'require_module';

use mop::bootstrap;

mop::bootstrap::init();

sub import {
    shift;
    my %options = @_;
    $^H{'mop/default_metaclass'} = $options{'-metaclass'}
        if $options{'-metaclass'};
    $^H{'mop/default_role_metaclass'} = $options{'-role_metaclass'}
        if $options{'-role_metaclass'};
    my $parser = $options{'-parser'} // 'mop::full::syntax';
    require_module($parser);
    $parser->setup_for( $options{'-into'} // caller )
}

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
