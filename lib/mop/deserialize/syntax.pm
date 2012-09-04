package mop::deserialize::syntax;

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
    my %methods = %{ mop::internal::instance::get_slot_at($::CLASS, '%methods') };
    mop::internal::instance::set_slot_at($methods{$name}, '$body', \Sub::Name::subname($name => $body));
}

sub has {
    my ($name, $ref, $metadata, $default) = @_;
    my %attributes = %{ mop::internal::instance::get_slot_at($::CLASS, '%attributes') };
    mop::internal::instance::set_slot_at($attributes{$name}, '$initial_value', \($default ? \$default : mop::internal::_undef_for_type($name)) );
}

sub BUILD {
    my ($body) = @_;
    my $method = ${ mop::internal::instance::get_slot_at($::CLASS, '$constructor') };
    mop::internal::instance::set_slot_at($method, '$body', \Sub::Name::subname('BUILD', $body));
}

sub DEMOLISH {
    my ($body) = @_;
    my $method = ${ mop::internal::instance::get_slot_at($::CLASS, '$destructor') };
    mop::internal::instance::set_slot_at($method, '$body', \Sub::Name::subname('DEMOLISH', $body));
}

sub super {
    goto &mop::syntax::super;
}

sub build_class {
    my ($name, $metadata, $caller) = @_;
    no strict 'refs';
    return ${ '::' . $name };
}

sub build_role {
    my ($name, $metadata, $caller) = @_;
    no strict 'refs';
    return ${ '::' . $name };
}

sub finalize_class {
    my ($name, $class, $caller) = @_;

    my $stash = mop::internal::get_stash_for($class);
    my $methods = {
        (map { %{ mop::internal::instance::get_slot_at($_, '%methods') } }
            (${ mop::internal::instance::get_slot_at($class, '$superclass') } || ()),
            @{ mop::internal::instance::get_slot_at($class, '@roles') },
            $class),
    };
    %$stash = ();
    for my $name (keys %$methods) {
        my $method = $methods->{$name};
        $stash->add_method($name => sub { $method->execute(@_) });
    }
    for my $attribute (values %{ mop::internal::instance::get_slot_at($class, '%attributes') }) {
        mop::internal::get_stash_for($::Attribute)->bless($attribute);
    }

    for my $method (values %{ mop::internal::instance::get_slot_at($class, '%methods') }) {
        mop::internal::get_stash_for($::Method)->bless($method);
    }
    if ($name eq 'Method') {
        $stash->add_method(execute => sub {
            mop::internal::execute_method(@_)
        });
    }
    $stash->add_method(DESTROY => mop::internal::generate_DESTROY());

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub () { $class } );
    }
}

sub finalize_role {
    my ($name, $role, $caller) = @_;

    for my $attribute (values %{ mop::internal::instance::get_slot_at($role, '%attributes') }) {
        mop::internal::get_stash_for($::Attribute)->bless($attribute);
    }

    for my $method (values %{ mop::internal::instance::get_slot_at($role, '%methods') }) {
        mop::internal::get_stash_for($::Method)->bless($method);
    }

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${caller}::${name}"} = Sub::Name::subname( $name, sub () { $role } );
    }
}

1;
