package Class::MOPX::Types;
use strict;
use warnings;
use mop;

use Scalar::Util 'looks_like_number';

class Constraint {
    has $name;

    has $constraint;
    has $parent;
    has $compiled_constraint;

    BUILD {
        die "name is required" unless defined $name;

        if ($parent) {
            $compiled_constraint //= sub {
                $parent->check(@_) && $constraint->(@_)
            };
        }
        else {
            $compiled_constraint //= $constraint;
        }
    }

    method subtype ($name, $constraint) {
        $class->new(
            name       => $name,
            constraint => $constraint,
        );
    }

    method check ($val) {
        $compiled_constraint->($val);
    }

    method validate ($val) {
        die "Type constraint $name failed with value $val"
            unless $self->check($val);
    }
}

class Registry {
    has $constraints;

    BUILD {
        $constraints = {};
        $constraints->{Any} = Constraint->new(
            name       => 'Any',
            constraint => sub { 1 }
        );
        $constraints->{Undef} = $constraints->{Any}->subtype(Undef => sub {
            !defined($_[0])
        });
        $constraints->{Defined} = $constraints->{Any}->subtype(Defined => sub {
            defined($_[0])
        });
        $constraints->{Value} = $constraints->{Defined}->subtype(Value => sub {
            !ref($_[0])
        });
        $constraints->{Ref} = $constraints->{Defined}->subtype(Ref => sub {
            ref($_[0])
        });
        $constraints->{Str} = $constraints->{Value}->subtype(Str => sub {
            ref(\$_[0]) eq 'SCALAR' || ref(\(my $val = $_[0])) eq 'SCALAR'
        });
        $constraints->{Num} = $constraints->{Str}->subtype(Num => sub {
            looks_like_number($_[0])
        });
        $constraints->{Int} = $constraints->{Num}->subtype(Int => sub {
            (my $val = $_[0]) =~ /\A-?[0-9]+\z/
        });
        $constraints->{ArrayRef} = $constraints->{Ref}->subtype(ArrayRef => sub {
            ref($_[0]) eq 'ARRAY'
        });
        $constraints->{HashRef} = $constraints->{Ref}->subtype(HashRef => sub {
            ref($_[0]) eq 'HASH'
        });
    }

    method type ($name) {
        $constraints->{$name}
    }
}

sub import {
    my $caller = caller;
    my $registry = Registry->new;
    {
        no strict 'refs';
        *{ $caller . '::T' } = sub () { $registry };
    }
}

1;
