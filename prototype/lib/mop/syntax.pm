package mop::syntax;

use strict;
use warnings;

use mop::syntax::dispatchable;

use PadWalker     ();
use Devel::Caller ();
use Sub::Name     ();

sub has (\$@) : lvalue {
    my $var      = shift;
    my %metadata = @_;

	my %names = reverse %{ PadWalker::peek_sub( Devel::Caller::caller_cv( 1 ) ) };
	my $name = $names{ $var };

    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$class'} }->add_attribute(
        ${ $pad->{'$class'} }->attribute_class->new(
            name          => $name,
            initial_value => $var,
            %metadata
        )
    );

    $$var;
}

sub method {
    my $body = pop @_;
    my ($name, %metadata) = @_;
    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$class'} }->add_method(
        ${ $pad->{'$class'} }->method_class->new(
            name => $name,
            body => Sub::Name::subname( $name, $body ),
            %metadata
        )
    );
}

sub extends {
    my ($superclass) = @_;
    my $pad = PadWalker::peek_my(2);
    ${ $pad->{'$class'} }->add_superclass( $superclass );
}

sub class {
    my $body = pop @_;
    my ($name, %metadata) = @_;

    my $class_Class = $::Class;
    if ( exists $metadata{ 'metaclass' } ) {
        $class_Class = delete $metadata{ 'metaclass' };
    }

    my $caller = caller();

    my $class = $class_Class->new(
        name => ($caller eq 'main' ? $name : "${caller}::${name}"),
        %metadata
    );
    {
        local $::CLASS = $class;
        $body->();
    }
    $class->FINALIZE;
    {
        no strict 'refs';
        *{"${caller}::${name}"} = sub () { $class };
    }
    $class;
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