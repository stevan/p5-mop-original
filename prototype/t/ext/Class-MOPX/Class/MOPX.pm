package Class::MOPX;
use strict;
use warnings;

use mop;

class Method (extends => $::Method) { }

class Attribute (extends => $::Attribute) {
    has $reader;
    has $writer;
    has $accessor;
    has $predicate;
    has $clearer;
    has $init_arg;
    has $builder;

    method accessor_class { Method }

    method reader    { $reader    }
    method writer    { $writer    }
    method accessor  { $accessor  }
    method predicate { $predicate }
    method clearer   { $clearer   }
    method init_arg  { $init_arg  }
    method builder   { $builder   }

    method has_reader    { defined $reader    }
    method has_writer    { defined $writer    }
    method has_accessor  { defined $accessor  }
    method has_predicate { defined $predicate }
    method has_clearer   { defined $clearer   }
    method has_init_arg  { defined $init_arg  }
    method has_builder   { defined $builder   }

    method create_reader {
        my $slot = $self->get_name;
        $self->accessor_class->new(
            name => $self->reader,
            body => sub {
                mop::internal::instance::get_slot_at($::SELF, $slot);
            },
        );
    }
    method create_writer {
        my $slot = $self->get_name;
        $self->accessor_class->new(
            name => $self->writer,
            body => sub {
                my $val = shift;
                mop::internal::instance::set_slot_at($::SELF, $slot, \$val);
            },
        );
    }
    method create_accessor {
        my $slot = $self->get_name;
        $self->accessor_class->new(
            name => $self->accessor,
            body => sub {
                if (@_) {
                    my $val = shift;
                    mop::internal::instance::set_slot_at($::SELF, $slot, \$val);
                }
                mop::internal::instance::get_slot_at($::SELF, $slot);
            },
        );
    }
    method create_predicate {
        my $slot = $self->get_name;
        $self->accessor_class->new(
            name => $self->predicate,
            body => sub {
                defined mop::internal::instance::get_slot_at($::SELF, $slot);
            },
        );
    }
    method create_clearer {
        my $slot = $self->get_name;
        $self->accessor_class->new(
            name => $self->clearer,
            body => sub {
                mop::internal::instance::set_slot_at($::SELF, $slot, undef);
            },
        );
    }

    method get_param_name {
        return $self->init_arg if $self->has_init_arg;
        super;
    }
}

class Class (extends => $::Class) {
    method attribute_class { Attribute }
    method method_class    { Method    }

    method install_accessors {
        my $dispatcher = $self->get_dispatcher;

        mop::WALKCLASS(
            $dispatcher,
            sub {
                my $c = shift;
                my $attributes = $c->get_attributes;
                for my $attr (values %$attributes) {
                    next unless $attr->isa(Attribute);

                    $self->add_method($attr->create_reader)
                        if $attr->has_reader;
                    $self->add_method($attr->create_writer)
                        if $attr->has_writer;
                    $self->add_method($attr->create_accessor)
                        if $attr->has_accessor;
                    $self->add_method($attr->create_predicate)
                        if $attr->has_predicate;
                    $self->add_method($attr->create_clearer)
                        if $attr->has_clearer;
                }
            }
        );
    }

    method apply_builders_to_constructor {
        my $constructor = $self->get_constructor;
        my $dispatcher  = $self->get_dispatcher;
        $self->set_constructor($self->method_class->new(
            name => 'BUILD',
            body => sub {
                my $instance = $::SELF;
                mop::WALKCLASS(
                    $dispatcher,
                    sub {
                        my $c = shift;
                        my $attributes = $c->get_attributes;
                        for my $attr (values %$attributes) {
                            next unless $attr->isa(Attribute);
                            next unless $attr->has_builder;
                            next if defined mop::internal::instance::get_slot_at(
                                $instance, $attr->get_name
                            );

                            my $builder = $attr->builder;
                            my $initial_value = $instance->$builder;
                            mop::internal::instance::set_slot_at(
                                $instance, $attr->get_name, \$initial_value
                            );
                        }
                    },
                );
                $constructor->execute if $constructor;
            },
        ));
    }

    method FINALIZE {
        $self->install_accessors;
        $self->apply_builders_to_constructor;
        super;
    }
}

sub import {
    mop->import(-metaclass => Class, -into => scalar(caller));
}

1;
