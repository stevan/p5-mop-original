package mop::syntax;

use strict;
use warnings;

use Sub::Name ();

sub setup_for {
    my $class = shift;
    my $pkg   = shift;
    {
        no strict 'refs';
        *{ $pkg . '::class'    } = \&class;
        *{ $pkg . '::method'   } = \&method;
        *{ $pkg . '::has'      } = \&has;
        *{ $pkg . '::BUILD'    } = \&BUILD;
        *{ $pkg . '::DEMOLISH' } = \&DEMOLISH;
    }
}

sub class { }

sub method {
    my ($name, $body) = @_;
    $::CLASS->add_method(
        $::CLASS->method_class->new(
            name => $name,
            body => Sub::Name::subname( $name, $body )
        )
    )
}

sub has {
    my ($name, $ref, $metadata, $default) = @_;
    $::CLASS->add_attribute(
        $::CLASS->attribute_class->new(
            name          => $name,
            initial_value => \$default,
            ($metadata ? %$metadata : ()),
        )
    );
}

sub BUILD {
    my ($body) = @_;
    $::CLASS->set_constructor(
        $::CLASS->method_class->new(
            name => 'BUILD',
            body => Sub::Name::subname( 'BUILD', $body )
        )
    )
}

sub DEMOLISH {
    my ($body) = @_;
    $::CLASS->set_destructor(
        $::CLASS->method_class->new(
            name => 'DEMOLISH',
            body => Sub::Name::subname( 'DEMOLISH', $body )
        )
    )
}

sub build_class {
    my ($name, $metadata) = @_;
    my %metadata = %{ $metadata || {} };

    my $caller = caller;

    my $class_Class = $::Class;
    if ( exists $metadata{ 'metaclass' } ) {
        $class_Class = delete $metadata{ 'metaclass' };
    }

    if ( exists $metadata{ 'extends' } ) {
        $metadata{ 'superclass' } = delete $metadata{ 'extends' };
    }

    my $superclass = $metadata{ 'superclass' };

    if ( $superclass ) {
        my $compatible = mop::internal::class::get_compatible_class(
            $class_Class,
            mop::internal::instance::get_class( $superclass )
        );
        $class_Class = $compatible
            if defined $compatible;
    }

    $class_Class->new(
        name => ($caller eq 'main' ? $name : "${caller}::${name}"),
        %metadata
    );
}

sub finalize_class {
    my ($name, $class) = @_;

    my $caller = caller;

    $class->FINALIZE;

    {
        no strict 'refs';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub () { $class } );
    }
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use mop::syntax;

=head1 DESCRIPTION

