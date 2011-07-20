package mop;

use strict;
use warnings;

use mop::class;
use mop::attribute;
use mop::method;

our %METACLASSES;

sub import {
    shift;
    my $pkg = caller;

    no strict 'refs';

    *{"${pkg}::class"}   = \&class;
    *{"${pkg}::has"}     = sub { die "Cannot call 'has' keyword outside a 'class' block" };
    *{"${pkg}::method"}  = sub { die "Cannot call 'method' keyword outside a 'class' block" };
    *{"${pkg}::__MOP__"} = sub { die "Cannot call '__MOP__' keyword outside a 'class' block" };
}

sub get_metaclass {
    my $name = shift;
    $METACLASSES{ $name } || die "No metaclass found for '$name'";
}

sub class {
    my $caller   = caller();
    my $name     = shift;
    my $body     = pop @_;
    my %metadata = @_;

    my $meta = mop::class->new(
        name     => $name,
        metadata => \%metadata
    );

    $METACLASSES{ $name } = $meta;

    no strict 'refs';
    no warnings 'redefine';

    local *{"${caller}::has"}     = sub { has( $meta, @_ )    };
    local *{"${caller}::method"}  = sub { method( $meta, @_ ) };
    local *{"${caller}::__MOP__"} = sub { $meta };

    $body->();

    return;
}

sub has {
    my $meta     = shift;
    my $name     = shift;
    my %metadata = @_;

    $meta->add_attribute(
        mop::attribute->new(
            name     => $name,
            metadata => \%metadata
        )
    );
}

sub method {
    my $meta     = shift;
    my $name     = shift;
    my $body     = pop @_;
    my %metadata = @_;

    $meta->add_method(
        mop::method->new(
            name     => $name,
            metadata => \%metadata,
            body     => $body
        )
    );
}

1;

__END__

=pod

=cut
