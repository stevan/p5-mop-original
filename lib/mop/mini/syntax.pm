package mop::mini::syntax;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use mop::mini::class;
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

sub class {}
sub role  {}

sub method { $::CLASS->add_method( @_ ) }

sub has {
    my ($name, $ref, $metadata, $default) = @_;
    $::CLASS->add_attribute( $name, $default );
}

sub BUILD    { $::CLASS->set_constructor( @_ ) }
sub DEMOLISH { $::CLASS->set_destructor( @_ )  }

sub build_class {
    my ($name, $metadata, $caller) = @_;
    my %metadata = %{ $metadata || {} };
    my $class = mop::mini::class->new( $caller eq 'main' ? $name : "${caller}::${name}", \%metadata );
    $class->set_superclass( $metadata{ 'extends' } ) if exists $metadata{ 'extends' };
    $class->set_roles( $metadata{ 'roles' } ) if exists $metadata{ 'roles' };
    $class;
}

sub build_role {
    build_class(@_);
}

sub finalize_class {
    my ($name, $class, $caller) = @_;
    $class->finalize;
    {
        no strict 'refs';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub { $class } );
    }
}

sub finalize_role {
    finalize_class(@_);
}

sub super {
    die "Cannot call super() outside of a method" unless defined $::SELF;
    my $invocant    = $::SELF;
    my $method_name = (split '::' => ((caller(2))[3]))[-1];
    my $dispatcher  = $::CLASS->get_dispatcher;
    # find the method currently being called
    my $method = mop::util::WALKMETH( $dispatcher, $method_name );
    while ( $method && $method ne $::CALLER ) {
        $method = mop::util::WALKMETH( $dispatcher, $method_name );
    }
    # and advance past it by one
    $method = mop::util::WALKMETH( $dispatcher, $method_name )
              || die "No super method ($method_name) found";
    $invocant->$method( @_ );
}


1;

__END__
