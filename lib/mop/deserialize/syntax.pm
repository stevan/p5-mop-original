package mop::deserialize::syntax;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Sub::Name 'subname';

use mop::internal qw(get_stash_for apply_overloading_for_stash);
use mop::internal::instance qw(get_slot_at set_slot_at);

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
    my %methods = %{ get_slot_at($::CLASS, '%methods') };
    set_slot_at($methods{$name}, '$body', \subname($name => $body));
}

sub has {
    my ($name, $ref, $metadata, $default) = @_;
    my %attributes = %{ get_slot_at($::CLASS, '%attributes') };
    set_slot_at(
        $attributes{$name},
        '$initial_value',
        \($default ? \$default : mop::util::undef_for_type($name))
    );
}

sub BUILD {
    my ($body) = @_;
    my $method = ${ get_slot_at($::CLASS, '$constructor') };
    set_slot_at($method, '$body', \subname('BUILD' => $body));
}

sub DEMOLISH {
    my ($body) = @_;
    my $method = ${ get_slot_at($::CLASS, '$destructor') };
    set_slot_at($method, '$body', \subname('DEMOLISH' => $body));
}

# this isn't used by the bootstrap anywhere currently, but this may need to be
# figured out if we want to serialize classes in general
sub super { ... }

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

    my $stash = get_stash_for($class);
    my $methods = {
        (map { %{ get_slot_at($_, '%methods') } }
             (${ get_slot_at($class, '$superclass') } || ()),
             @{ get_slot_at($class, '@roles') },
             $class),
    };

    %$stash = ();

    for my $name (keys %$methods) {
        my $method = $methods->{$name};
        $stash->add_method($name => sub { $method->execute(@_) });
    }

    $stash->add_method(DESTROY => mop::internal::generate_DESTROY());

    apply_overloading_for_stash($stash);

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${caller}::${name}"} = subname($name => sub () { $class });
    }
}

sub finalize_role {
    my ($name, $role, $caller) = @_;

    {
        no strict 'refs';
        no warnings 'redefine';
        *{"${caller}::${name}"} = subname($name => sub () { $role });
    }
}

1;
