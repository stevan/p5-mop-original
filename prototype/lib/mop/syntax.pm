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
        *{ $pkg . '::method'   } = sub (&)  {};
        *{ $pkg . '::has'      } = sub ($@) {};
        *{ $pkg . '::BUILD'    } = sub (&)  {};
        *{ $pkg . '::DEMOLISH' } = sub (&)  {};
        *{ $pkg . '::super'    } = sub (@)  {};
    }

    my $context = $class->new;
    Devel::Declare->setup_for(
        $pkg,
        {
            'class'    => { const => sub { $context->class_parser( @_ )     } },
            'method'   => { const => sub { $context->method_parser( @_ )    } },
            'has'      => { const => sub { $context->attribute_parser( @_ ) } },
            'BUILD'    => { const => sub { $context->BUILD_parser( @_ )     } },
            'DEMOLISH' => { const => sub { $context->DEMOLISH_parser( @_ )  } },
            'super'    => { const => sub { $context->super_parser( @_ )     } },
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
            $::CLASS->method_class->new(
                name => $name,
                body => Sub::Name::subname( $name, $body )
            )
        )
    } );

    return;
}

sub BUILD_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;

    my $proto  = $self->strip_proto;
    my $inject = $self->scope_injector_call;
    $inject .= 'my (' . $proto . ') = @_;' if $proto;

    $self->inject_if_block( $inject );
    $self->shadow( sub (&) {
        my $body = shift;
        $::CLASS->set_constructor(
            $::CLASS->method_class->new(
                name => 'BUILD',
                body => Sub::Name::subname( 'BUILD', $body )
            )
        )
    } );

    return;
}

sub DEMOLISH_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;
    $self->inject_if_block( $self->scope_injector_call );
    $self->shadow( sub (&) {
        my $body = shift;
        $::CLASS->set_destructor(
            $::CLASS->method_class->new(
                name => 'DEMOLISH',
                body => Sub::Name::subname( 'DEMOLISH', $body )
            )
        )
    } );

    return;
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
        mop::internal::execute_method( $method, $invocant, @_ );
    });

    return;
}

sub attribute_parser {
    my $self = shift;

    $self->init( @_ );

    $self->skip_declarator;
    $self->skipspace;

    my $name;

    my $linestr = $self->get_linestr;
    if ( substr( $linestr, $self->offset, 1 ) eq '$' ) {
        my $length = Devel::Declare::toke_scan_ident( $self->offset );
        $name = substr( $linestr, $self->offset, $length );

        my $full_length = $length;
        my $old_offset  = $self->offset;

        $self->inc_offset( $length );
        $self->skipspace;

        my $proto;
        if ( substr( $linestr, $self->offset, 1 ) eq '(' ) {
            my $length = Devel::Declare::toke_scan_str( $self->offset );
            $proto = Devel::Declare::get_lex_stuff();
            $full_length += $length;
            Devel::Declare::clear_lex_stuff();
            $self->inc_offset( $length );
        }

        $self->skipspace;
        if ( substr( $linestr, $self->offset, 1 ) eq '=' ) {
            $self->inc_offset( 1 );
            $self->skipspace;
            if ( substr( $linestr, $self->offset, 2 ) eq 'do' ) {
                substr( $linestr, $self->offset, 2 ) = 'sub';
            }
        }

        substr( $linestr, $old_offset, $full_length ) = '(\(my ' . $name . ')' . ( $proto ? (', (' . $proto) : '') . ')';

        $self->set_linestr( $linestr );
        $self->inc_offset( $full_length );
    }

    $self->shadow(sub ($@) : lvalue {
        shift;
        my %metadata = @_;
        my $initial_value;
        $::CLASS->add_attribute(
            $::CLASS->attribute_class->new(
                name          => $name,
                initial_value => \$initial_value,
                %metadata
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

