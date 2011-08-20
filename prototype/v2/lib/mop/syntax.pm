package mop::syntax;

use strict;
use warnings;

use mop::syntax::dispatchable;

use PadWalker    ();
use Scalar::Util ();

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
        'methods'      => {},
        'superclasses' => [],
    };

    my $attrs = PadWalker::peek_sub( $body );

    # NOTE:
    # we need to use some guessing here to
    # make sure we are only capturing the
    # variable actually intended as attributes
    # and not other lexicals PadWalker might
    # see. So the first thing we do is get
    # rid of $self and $class, which we know
    # are not acceptable.

    delete $attrs->{'$self'};
    delete $attrs->{'$class'};

    # The next thing we do is to remove any
    # closed over classes, such as would occur
    # with the 'extends' statement.

    foreach my $attr ( keys %$attrs ) {
        delete $attrs->{ $attr }
            if Scalar::Util::blessed ${ $attrs->{ $attr } };
    }

    # none of the above technique for
    # cleaning the attrs HASH are ideal
    # but this is just a hacked up sugar
    # layer, so we live with it for the
    # protototype.

    $meta->{'attributes'} = $attrs;

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

==head1 TODO

improve the handling and detection of attributes, right now it
is too much guessing.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut