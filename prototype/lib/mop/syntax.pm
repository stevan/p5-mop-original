package mop::syntax;

use strict;
use warnings;

use mop::syntax::dispatchable;

use base 'Devel::Declare::Context::Simple';

use Sub::Name      ();
use Devel::Declare ();
use B::Hooks::EndOfScope;
use Carp qw[ confess ];

sub setup_for {
    my $class = shift;
    my $pkg   = shift;
    {
        no strict 'refs';
        *{ $pkg . '::class'  } = sub (&@) {};
        *{ $pkg . '::method' } = sub (&)  {};
        *{ $pkg . '::has'    } = sub ($)  {};
        *{ $pkg . '::BUILD'  } = sub (&)  {
            my $body = shift;
            $::CLASS->set_constructor(
                $::CLASS->method_class->new(
                    name => 'BUILD',
                    body => Sub::Name::subname( 'BUILD', $body )
                )
            )
        };
    }

    my $context = $class->new;
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
    my $caller = $self->get_curstash_name;

    my $inject = $self->scope_injector_call
               . 'my $d = shift;'
               . '$d->{"class"} = ' . __PACKAGE__ . '->build_class('
                    . 'name   => "' . $name . '", '
                    . 'caller => "' . $caller . '"'
                    . ($proto ? (', ' . $proto) : '')
               . ');'
               . 'local $::CLASS = $d->{"class"};'
               . 'my ($self, $class);';
    $self->inject_if_block( $inject );

    $self->shadow(sub (&@) {
        my $body = shift;
        my $data = {};

        $body->( $data );

        my $class = $data->{'class'};
        $class->FINALIZE;

        {
            no strict 'refs';
            *{"${caller}::${name}"} = Sub::Name::subname( $name, sub () { $class } );
        }

        return;
    });

    return;
}

sub build_class {
    shift;
    my %metadata = @_;

    my $name   = delete $metadata{ 'name' };
    my $caller = delete $metadata{ 'caller' };

    my $class_Class = $::Class;
    if ( exists $metadata{ 'metaclass' } ) {
        $class_Class = delete $metadata{ 'metaclass' };
    }

    if ( exists $metadata{ 'extends' } ) {
        $metadata{ 'superclasses' } = [ delete $metadata{ 'extends' } ];
    }

    $class_Class->new(
        name => ($caller eq 'main' ? $name : "${caller}::${name}"),
        %metadata
    );
}

sub method_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;

    my $name   = $self->strip_name;
    my $proto  = $self->strip_proto;
    my $inject = $self->scope_injector_call;
    $inject .= 'my (' . $proto . ') = @_;' if $proto;

    $self->inject_if_block( $inject );
    $self->shadow( sub (&) {
        my $body = shift;
        $::CLASS->add_method(
            $::Method->new(
                name => $name,
                body => Sub::Name::subname( $name, $body )
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

sub inject_scope {
    my $class  = shift;
    my $inject = shift || ';';
    on_scope_end {
        my $linestr = Devel::Declare::get_linestr;
        return unless defined $linestr;
        my $offset  = Devel::Declare::get_linestr_offset;
        if ( $inject eq ';' ) {
            substr( $linestr, $offset, 0 ) = $inject;
        }
        else {
            substr( $linestr, $offset - 1, 0 ) = $inject;
        }
        Devel::Declare::set_linestr($linestr);
    };
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use mop::syntax;

=head1 DESCRIPTION

