package explicit::override;
use strict;
use warnings;

use mop;
use List::MoreUtils 'any';

class ExplicitOverride (extends => $::Class) {
    method add_method ($method, $override) {
        # XXX need a find_method that checks mro on its own
        die "Overriding method " . $method->get_name . " without using override"
            if !$override && any { $_->find_method($method->get_name) } @{ $self->get_mro };
        super($method);
    }

    method override_method ($method) {
        $self->add_method($method, 1);
    }
}

# XXX add method parser for this
sub override ($&) {
    my ($name, $sub) = @_;
    $::CLASS->add_method(
        $::CLASS->method_class->new(
            name => $name, body => $sub
        ),
        1
    )
}

sub import {
    my $caller = caller;
    mop->import(-metaclass => ExplicitOverride);
    no strict 'refs';
    *{ $caller . '::override'} = \&override;
}

1;
