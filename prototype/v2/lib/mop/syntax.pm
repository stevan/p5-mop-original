package mop::syntax;

use strict;
use warnings;

use mop::syntax::dispatchable;

use PadWalker     ();
use Devel::Caller ();

sub has (\$) {
    my $var = shift;

	my %names = reverse %{ PadWalker::peek_sub( Devel::Caller::caller_cv( 1 ) ) };
	my $name = $names{ $var };

    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$meta'} }->{'attributes'}->{ $name } = $var;
}

sub method {
    my ($name, $body) = @_;
    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$meta'} }->{'methods'}->{ $name } = $body;
}

sub extends {
    my ($superclass) = @_;
    my $pad = PadWalker::peek_my(2);
    push @{ ${ $pad->{'$meta'} }->{'superclasses'} } => $superclass;
}

sub class (&) {
    my $body = shift;

    my $meta = {
        'attributes'   => {},
        'methods'      => {},
        'superclasses' => [],
    };

    $body->();

    push @{ $meta->{'superclasses'} } => $::Object
        unless scalar @{ $meta->{'superclasses'} };

    $::Class->new( %$meta );
}

1;

__END__

=pod

=head1 NAME

mop::syntax

=head1 DESCRIPTION

The primary responsibility of these 3 functions is to provide a
sugar layer for the creation of classes. Exactly how this would
work in a real implementation is unknown, but this does the job
(in a kind of scary PadWalker-ish way) for now.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut