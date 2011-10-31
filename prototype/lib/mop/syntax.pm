package mop::syntax;

use strict;
use warnings;

use Devel::Declare ();
use Sub::Name ();

use base 'Devel::Declare::MethodInstaller::Simple';

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
        *{ $pkg . '::super'    } = sub (@)  {};
    }

    my $context = $class->new;
    Devel::Declare->setup_for(
        $pkg,
        {
            'super'    => { const => sub { $context->super_parser( @_ )     } },
        }
    );
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
    my ($name, $metadata, $caller) = @_;
    my %metadata = %{ $metadata || {} };

    my $class_Class = $::Class;
    if ( exists $metadata{ 'metaclass' } ) {
        $class_Class = delete $metadata{ 'metaclass' };
    }

    if ( exists $metadata{ 'extends' } ) {
        $metadata{ 'superclass' } = delete $metadata{ 'extends' };
    }

    my $superclass = $metadata{ 'superclass' };

    if ( $superclass ) {
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

sub finalize_class {
    my ($name, $class, $caller) = @_;

    $class->FINALIZE;

    {
        no strict 'refs';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub () { $class } );
    }
}

sub super_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;
    $self->shadow(sub (@) {
        die "Cannot call super() outside of a method" unless defined $::SELF;
        my $invocant    = $::SELF;
        my $method_name = (split '::' => ((caller(1))[3]))[-1];
        my $dispatcher  = $::CLASS->get_dispatcher;
        mop::WALKMETH( $dispatcher, $method_name ); # discard the first one ...
        my $method = mop::WALKMETH( $dispatcher, $method_name )
                     || die "No super method found for '$method_name'";
        $method->execute( $invocant, @_ );
    });

    return;
}

1;

__END__

# ABSTRACT: A Moosey solution to this problem

=head1 SYNOPSIS

  use mop::syntax;

=head1 DESCRIPTION

