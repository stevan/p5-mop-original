package mop::syntax;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Sub::Name ();

use mop::parser;

mop::parser::init_parser_for(__PACKAGE__);

sub setup_for {
    my $class = shift;
    my $pkg   = shift;
    {
        no strict 'refs';
        *{ $pkg . '::class'    } = \&class;
        *{ $pkg . '::role'     } = \&role;
        *{ $pkg . '::method'   } = \&method;
        *{ $pkg . '::has'      } = \&has;
        *{ $pkg . '::BUILD'    } = \&BUILD;
        *{ $pkg . '::DEMOLISH' } = \&DEMOLISH;
        *{ $pkg . '::super'    } = \&super;
    }
}

sub class { }

sub role { }

sub method {
    my ($name, $body) = @_;
    $::CLASS->add_method(
        $::CLASS->method_class->new(
            name => $name,
            ($body
                ? (body => Sub::Name::subname( $name, $body ))
                : ()),
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

sub super {
    die "Cannot call super() outside of a method" unless defined $::SELF;
    my $invocant    = $::SELF;
    my $method_name = (split '::' => ((caller(1))[3]))[-1];
    my $dispatcher  = $::CLASS->get_dispatcher;
    # find the method currently being called
    my $method = mop::WALKMETH( $dispatcher, $method_name );
    while ( $method != $::CALLER ) {
        $method = mop::WALKMETH( $dispatcher, $method_name );
    }
    # and advance past it  by one
    $method = mop::WALKMETH( $dispatcher, $method_name )
              || die "No super method ($method_name) found";
    $method->execute( $invocant, @_ );
}

sub build_class {
    my ($name, $metadata, $caller) = @_;
    my %metadata = %{ $metadata || {} };

    my $class_Class = $^H{'mop/default_metaclass'} // $::Class;
    if ( exists $metadata{ 'metaclass' } ) {
        $class_Class = delete $metadata{ 'metaclass' };
    }

    if ( exists $metadata{ 'extends' } ) {
        $metadata{ 'superclass' } = delete $metadata{ 'extends' };
    }

    if ( exists $metadata{ 'with' } ) {
        $metadata{ 'roles' } = delete $metadata{ 'with' };
    }

    if ( exists $metadata{ 'does' } ) {
        $metadata{ 'roles' } = delete $metadata{ 'does' };
    }

    my $superclass = $metadata{ 'superclass' };

    if ( $superclass && ref($class_Class) ne 'mop::mini::class' ) {
        my $compatible = $class_Class->get_compatible_class(
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

sub build_role {
    my ($name, $metadata, $caller) = @_;
    my %metadata = %{ $metadata || {} };

    my $role_Class = $^H{'mop/default_role_metaclass'} // $::Role;
    if ( exists $metadata{ 'metaclass' } ) {
        $role_Class = delete $metadata{ 'metaclass' };
    }

    if ( exists $metadata{ 'with' } ) {
        $metadata{ 'roles' } = delete $metadata{ 'with' };
    }

    if ( exists $metadata{ 'does' } ) {
        $metadata{ 'roles' } = delete $metadata{ 'does' };
    }

    $role_Class->new(
        name => ($caller eq 'main' ? $name : "${caller}::${name}"),
        %metadata
    );
}

sub finalize_class {
    my ($name, $class, $caller) = @_;

    $class->FINALIZE;

    {
        no strict 'refs';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub { $class } );
    }
}

sub finalize_role {
    my ($name, $role, $caller) = @_;

    $role->FINALIZE;

    {
        no strict 'refs';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub { $role } );
    }
}

1;

__END__

=pod

=head1 NAME

mop::syntax - The syntax module for the p5-mop

=head1 SYNOPSIS

  use mop::syntax;

=head1 DESCRIPTION

This module uses Devel::CallParser to provide the desired
syntax for the p5-mop.

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
