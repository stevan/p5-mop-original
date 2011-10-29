package mop::syntax;

use strict;
use warnings;

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
        *{ $pkg . '::class'    } = sub (&@) {};
        *{ $pkg . '::method'   } = \&method;
        *{ $pkg . '::has'      } = \&has;
        *{ $pkg . '::BUILD'    } = \&BUILD;
        *{ $pkg . '::DEMOLISH' } = \&DEMOLISH;
    }

    my $context = $class->new;
    Devel::Declare->setup_for(
        $pkg,
        {
            'class' => { const => sub { $context->class_parser( @_ )     } },
        }
    );
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

sub method {
    my ($name, $body) = @_;
    $::CLASS->add_method(
        $::CLASS->method_class->new(
            name => $name,
            body => Sub::Name::subname( $name, $body )
        )
    )
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

