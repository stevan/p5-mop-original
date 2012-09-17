package mop::mini::class;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use Hash::Util::FieldHash qw[ fieldhashes ];
use Sub::Name             qw[ subname ];
use PadWalker             qw[ set_closed_over ];
use Scope::Guard          qw[ guard ];
use Scalar::Util          qw[ weaken ];

use mop::internal::instance qw(
    create_instance
    get_uuid get_class get_slots
    set_class
    get_slot_at set_slot_at
);
use mop::util;

use parent 'Package::Anon';

fieldhashes \ my (
    %name,
    %is_role,
    %superclass,
    %roles,
    %constructor,
    %destructor,
    %attributes,
    %methods
);

sub new {
    if ( ref $_[0] ) {
        my $class = shift;
        my %args  = scalar @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

        my %attrs = (
            (map { %{ $_->attributes || {} } }
                 @{ $class->roles || [] }),
            %{ $class->attributes || {} },
        );

        # XXX
        mop::internal::instance::_set_offset_map($class, [ sort keys %attrs ]);
        my $instance = create_instance($class, {});
        foreach my $attr ( keys %attrs ) {
            my ($sigil, $plain_attr) = ($attr =~ /^([\$\@\%])(.*)/);
            if ( exists $args{ $plain_attr } ) {
                if ($sigil eq '$') {
                    set_slot_at($instance, $attr, \($args{ $plain_attr }));
                }
                else {
                    set_slot_at($instance, $attr, $args{ $plain_attr });
                }
            }
            else {
                if ($sigil eq '$') {
                    set_slot_at(
                        $instance,
                        $attr,
                        (ref $attrs{ $attr } eq 'CODE'
                            ? \($attrs{ $attr }->())
                            : \($attrs{ $attr }))
                    );
                }
                elsif ($sigil eq '@') {
                    set_slot_at(
                        $instance,
                        $attr,
                        (ref $attrs{ $attr } eq 'CODE'
                            ? [ $attrs{ $attr }->() ]
                            : (defined $attrs{ $attr } ? $attrs{ $attr } : []))
                    );
                }
                elsif ($sigil eq '%') {
                    set_slot_at(
                        $instance,
                        $attr,
                        (ref $attrs{ $attr } eq 'CODE'
                            ? { $attrs{ $attr }->() }
                            : (defined $attrs{ $attr } ? $attrs{ $attr } : {}))
                    );
                }
                else {
                    die "unknown sigil $sigil";
                }
            }
        }

        my $self = $class->bless( $instance );
        mop::util::WALKCLASS(
            $class->dispatcher('reverse'),
            sub { ( $_[0]->constructor || return )->( $self, \%args ); return }
        );
        $self;
    }
    else {
        my ($pkg, $name) = @_;
        my $class = $pkg->SUPER::new( $name );
        $class->set_name( $name );
        $class;
    }
}

sub name             { $name{ $_[0] }          }
sub is_role          { $is_role{ $_[0] }       }
sub superclass       { $superclass{ $_[0] }    }
sub local_roles      { $roles{ $_[0] }         }
sub local_attributes { $attributes{ $_[0] }    }
sub local_methods    { $methods{ $_[0] }       }
sub constructor      { $constructor{ $_[0] }   }
sub destructor       { $destructor{ $_[0] }    }

sub set_name       { $name{ $_[0] } = $_[1]       }
sub set_is_role    { $is_role{ $_[0] } = $_[1]    }
sub set_superclass { $superclass{ $_[0] } = $_[1] }
sub set_roles      { $roles{ $_[0] } = $_[1]      }

sub set_constructor {
    my ($class, $body) = @_;
    $constructor{ $class } = $class->_create_method( 'BUILD' => $body )
}

sub set_destructor {
    my ($class, $body) = @_;
    $destructor{ $class } = $class->_create_method( 'DEMOLISH' => $body )
}

sub mro {
    my $class = shift;
    my $super = $class->superclass;
    return [ $class, $super ? @{ $super->mro } : () ];
}

sub instance_isa {
    my ($class, $super) = @_;
    my @mro = @{ $class->mro };
    return !!grep { $super eq $_ } @mro;
}

sub dispatcher {
    my ($class, $type) = @_;
    return sub { state $mro = $class->mro; shift @$mro } unless $type;
    return sub { state $mro = $class->mro; pop   @$mro } if $type eq 'reverse';
}

sub methods {
    my $class = shift;
    my %methods;
    mop::util::WALKCLASS(
        $class->dispatcher('reverse'),
        sub {
            my $c = shift;
            %methods = (
                %methods,
                %{ $c->local_methods || {} },
            );
        }
    );
    \%methods;
}

sub attributes {
    my $class = shift;
    my %attrs;
    mop::util::WALKCLASS(
        $class->dispatcher('reverse'),
        sub {
            my $c = shift;
            %attrs = (
                %attrs,
                %{ $c->local_attributes || {} },
            );
        }
    );
    \%attrs;
}

sub roles {
    my $class = shift;

    my @roles;
    mop::util::WALKCLASS(
        $class->dispatcher('reverse'),
        sub {
            my $c = shift;
            push @roles, (
                map { $_, @{ $_->local_roles || [] } }
                    @{ $c->local_roles || [] },
            );
        }
    );
    return \@roles;
}

sub add_attribute {
    my ($class, $name, $constructor) = @_;
    $attributes{ $class } = {} unless exists $attributes{ $class };
    $attributes{ $class }->{ $name } = $constructor;
}

sub add_method {
    my ($class, $name, $body) = @_;
    $methods{ $class } = {} unless exists $methods{ $class };
    $methods{ $class }->{ $name } = $class->_create_method( $name, $body );
}

sub finalize {
    my $class  = shift;

    my $methods = $class->methods;

    foreach my $name ( keys %$methods ) {
        my $method = $methods->{ $name };
        $class->SUPER::add_method(
            $name,
            $method
        ) unless exists $class->{ $name };
    }

    my %role_methods = map { %{ $_->local_methods || {} } }
                           @{ $class->roles || [] };

    foreach my $name ( keys %role_methods ) {
        my $method = $role_methods{ $name };
        $class->add_method($name, $method)
            unless exists $class->methods->{$name};
        $class->SUPER::add_method(
            $name,
            $method
        ) unless exists $class->{ $name };
    }

    my %role_attributes = map { %{ $_->local_attributes || {} } }
                              @{ $class->roles || [] };

    foreach my $name ( keys %role_attributes ) {
        my $attribute = $role_attributes{ $name };
        $class->add_attribute($name, $attribute)
            unless exists $class->attributes->{$name};
    }

    $class->SUPER::add_method('isa' => sub {
        my ($self, $other) = @_;
        $class->instance_isa($other);
    });

    $class->SUPER::add_method('DESTROY' => sub {
        my $self = shift;
        return unless $class; # likely in global destruction ...
        mop::util::WALKCLASS(
            $class->dispatcher,
            sub { ( $_[0]->destructor || return )->( $self ); return }
        );
    });
}

sub _create_method {
    my ($class, $name, $body) = @_;

    my $method_name = join '::' => ($class->name || ()), $name;

    my $method;
    $method = subname(
        $method_name => sub {
            state $STACK = [];

            my $invocant = shift;
            weaken($invocant);

            my $instance = get_slots( $invocant );
            my $class    = get_class( $invocant );

            my $env      = {
                %$instance,
                '$self'  => \$invocant,
                '$class' => \$class
            };

            push @$STACK => $env;
            set_closed_over( $body, $env );

            my $g = guard {
                pop @$STACK;
                if ( my $env = $STACK->[-1] ) {
                    set_closed_over( $body, $env );
                }
                else {
                    set_closed_over( $body, {
                        (map { $_ => mop::util::undef_for_type($_) }
                             keys %$instance),
                        '$self'  => \undef,
                        '$class' => \undef,
                    });
                }
            };

            local $::SELF   = $invocant;
            local $::CLASS  = $class;
            local $::CALLER = $method;

            $body->( @_ );
        }
    );
}

1;
