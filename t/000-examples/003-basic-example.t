#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

role Eq {
    method equal_to;

    method not_equal_to ($other) {
        not $self->equal_to($other);
    }
}

role Comparable ( with => [Eq] ) {
    method compare;
    method equal_to ($other) {
        $self->compare($other) == 0;
    }

    method greater_than ($other)  {
        $self->compare($other) == 1;
    }

    method less_than  ($other) {
        $self->compare($other) == -1;
    }

    method greater_than_or_equal_to ($other)  {
        $self->greater_than($other) || $self->equal_to($other);
    }

    method less_than_or_equal_to ($other)  {
        $self->less_than($other) || $self->equal_to($other);
    }
}

role Printable {
    method to_string;
}

class US::Currency ( with => [ Comparable, Printable ] ) {
    has $amount = 0;

    method amount { $amount }

    method compare ($other) {
        $amount <=> $other->amount;
    }

    method to_string {
        sprintf '$%0.2f USD' => $amount;
    }
}

SKIP: { skip "Requires the full mop", 4 if $ENV{PERL_MOP_MINI}; $::Class = $::Class;
is(mop::class_of(Eq), $::Role, '... Eq is a role');
is(mop::class_of(Comparable), $::Role, '... Comparable is a role');
is(mop::class_of(Printable), $::Role, '... Printable is a role');
is(mop::class_of(US::Currency), $::Class, '... US::Currency is a class');
}
TODO: { todo_skip "instance_does not yet implemented", 4 if $ENV{PERL_MOP_MINI};
ok(Comparable->instance_does( Eq ), '... Comparable does the Eq role');
ok(US::Currency->instance_does( Eq ), '... US::Currency does Eq');
ok(US::Currency->instance_does( Comparable ), '... US::Currency does Comparable');
ok(US::Currency->instance_does( Printable ), '... US::Currency does Printable');
}

SKIP: { skip "Requires the full mop", 2 if $ENV{PERL_MOP_MINI};
ok(Eq->find_method('equal_to')->is_stub, '... EQ::equal_to is a stub method');
ok(!Eq->find_method('not_equal_to')->is_stub, '... EQ::not_equal_to is NOT a stub method');
}

my $dollar = US::Currency->new( amount => 10 );
ok($dollar->isa( US::Currency ), '... the dollar is a US::Currency instance');
TODO: { todo_skip "does not yet implemented", 3 if $ENV{PERL_MOP_MINI};
ok($dollar->does( Eq ), '... the dollar does the Eq role');
ok($dollar->does( Comparable ), '... the dollar does the Comparable role');
ok($dollar->does( Printable ), '... the dollar does the Printable role');
}

TODO: { local $TODO = "role application is broken" if $ENV{PERL_MOP_MINI};
can_ok($dollar, 'equal_to');
can_ok($dollar, 'not_equal_to');

can_ok($dollar, 'greater_than');
can_ok($dollar, 'greater_than_or_equal_to');
can_ok($dollar, 'less_than');
can_ok($dollar, 'less_than_or_equal_to');
}

can_ok($dollar, 'compare');
can_ok($dollar, 'to_string');

is($dollar->to_string, '$10.00 USD', '... got the right to_string value');

TODO: { todo_skip "role application is broken", 6 if $ENV{PERL_MOP_MINI};
ok($dollar->equal_to( $dollar ), '... we are equal to ourselves');
ok(!$dollar->not_equal_to( $dollar ), '... we are not not equal to ourselves');

ok(US::Currency->new( amount => 20 )->greater_than( $dollar ), '... 20 is greater than 10');
ok(!US::Currency->new( amount => 2 )->greater_than( $dollar ), '... 2 is not greater than 10');

ok(!US::Currency->new( amount => 10 )->greater_than( $dollar ), '... 10 is not greater than 10');
ok(US::Currency->new( amount => 10 )->greater_than_or_equal_to( $dollar ), '... 10 is greater than or equal to 10');
}


done_testing;
