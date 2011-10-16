package mop::declare;

use strict;
use warnings;

use base 'Devel::Declare::Context::Simple';

use Devel::Declare ();
use B::Hooks::EndOfScope;
use Carp qw[ confess ];

sub import {
    my $pkg   = caller;
    my $class = shift;
    my %args  = @_;
    {
        no strict 'refs';
        *{ $pkg . '::class'  } = sub (&) {};
        *{ $pkg . '::method' } = sub (&) {};
        *{ $pkg . '::has'    } = sub ($) {};
    }

    my $context = $class->new( %args );

    Devel::Declare->setup_for(
        $pkg,
        {
            'class'  => { const => sub { $context->class_parser( @_ ) } },
            'method' => { const => sub { $context->method_parser( @_ )    } },
            'has'    => { const => sub { $context->attribute_parser( @_ ) } },
        }
    );
}

sub class_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;

    my $name   = $self->strip_name;
    my $proto  = $self->strip_proto;

    my $inject = $self->scope_injector_call();
    $self->inject_if_block( $inject );

    $self->shadow(sub (&) {
        my $body   = shift;
        my $caller = $self->get_curstash_name;
        my $class  = $::Class->new(
            name => ($caller eq 'main' ? $name : "${caller}::${name}")
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
    });

    return;
}

sub method_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;

    my $name   = $self->strip_name;
    my $proto  = $self->strip_proto;
    my $inject = $self->scope_injector_call();
    $inject .= 'my (' . $proto . ') = @_;' if $proto;

    $self->inject_if_block( $inject );
    $self->shadow( sub (&) {
        my $body = shift;
        $::CLASS->add_method(
            $::Method->new(
                name => $name,
                body => $body
            )
        )
    } );

    return;
}

sub attribute_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;
    $self->skipspace;

    my $name;

    my $linestr = $self->get_linestr;
    my $next    = substr( $linestr, $self->offset, 1 );
    if ( $next eq '$' ) { # || $next eq '@' || $next eq '%' ) {
        my $length = Devel::Declare::toke_scan_ident( $self->offset );
        $name = substr( $linestr, $self->offset, $length  );
        substr( $linestr, $self->offset, $length ) = '(\(my ' . $name . '))';
        $self->set_linestr( $linestr );
    }

    $self->shadow(sub ($) : lvalue {
        my $initial_value;
        $::CLASS->add_attribute(
            $::Attribute->new(
                name          => $name,
                initial_value => \$initial_value
            )
        );
        $initial_value
    });

    return;
}


1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use mop::declare;

=head1 DESCRIPTION

