package Class::MOPX;
use strict;
use warnings;

use mop;

class Attribute (extends => $::Attribute) {
    has $reader;
    has $writer;
    has $accessor;
    has $predicate;
    has $clearer;
    # has $builder;
    # has $init_arg;

    method reader    { $reader    }
    method writer    { $writer    }
    method accessor  { $accessor  }
    method predicate { $predicate }
    method clearer   { $clearer   }

    method has_reader    { defined $reader    }
    method has_writer    { defined $writer    }
    method has_accessor  { defined $accessor  }
    method has_predicate { defined $predicate }
    method has_clearer   { defined $clearer   }
}

class Method (extends => $::Method) { }

class Class (extends => $::Class) {
    method attribute_class { Attribute }
    method method_class    { Method    }

    method install_accessor ($name, $body) {
        $self->add_method(Method->new(
            name => $name,
            body => $body,
        ));
    }

    method install_accessors {
        my $dispatcher = $self->get_dispatcher;

        mop::WALKCLASS(
            $dispatcher,
            sub {
                my $c = shift;
                my $attributes = $c->get_attributes;
                for my $attr (values %$attributes) {
                    next unless $attr->isa(Attribute);

                    if ($attr->has_reader) {
                        $self->install_accessor($attr->reader => sub {
                            mop::internal::instance::get_slot_at(
                                $::SELF, $attr->get_name
                            );
                        });
                    }
                    if ($attr->has_writer) {
                        $self->install_accessor($attr->writer => sub {
                            my $val = shift;
                            mop::internal::instance::set_slot_at(
                                $::SELF, $attr->get_name, \$val
                            );
                        });
                    }
                    if ($attr->has_accessor) {
                        $self->install_accessor($attr->accessor => sub {
                            if (@_) {
                                my $val = shift;
                                mop::internal::instance::set_slot_at(
                                    $::SELF, $attr->get_name, \$val
                                );
                            }
                            mop::internal::instance::get_slot_at(
                                $::SELF, $attr->get_name
                            );
                        });
                    }
                    if ($attr->has_predicate) {
                        $self->install_accessor($attr->predicate => sub {
                            defined mop::internal::instance::get_slot_at(
                                $::SELF, $attr->get_name
                            );
                        });
                    }
                    if ($attr->has_clearer) {
                        $self->install_accessor($attr->clearer => sub {
                            mop::internal::instance::set_slot_at(
                                $::SELF, $attr->get_name, undef
                            );
                        });
                    }
                }
            }
        );
    }

    method FINALIZE {
        $self->install_accessors;
        super;
    }
}

sub import {
    mop->import(-metaclass => Class);
}

1;
