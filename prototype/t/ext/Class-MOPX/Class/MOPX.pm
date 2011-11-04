package Class::MOPX;
use strict;
use warnings;

use mop;

use Scalar::Util 'weaken';

class Method (extends => $::Method) {
    has $associated_class;

    method associated_class ($class) {
        weaken($associated_class = $class)
            if $class;
        $associated_class;
    }
}

class Attribute (extends => $::Attribute) {
    has $associated_class;

    has $constraint;
    has $reader;
    has $writer;
    has $accessor;
    has $predicate;
    has $clearer;
    has $init_arg;
    has $builder;
    has $lazy;

    BUILD ($params) {
        if (my $is = $params->{is}) {
            (my $method = $self->get_name) =~ s/^\$//;
            if ($is eq 'ro') {
                $reader = $method;
            }
            elsif ($is eq 'rw') {
                $accessor = $method;
            }
        }
        if (my $isa = $params->{isa}) {
            $constraint = $isa;
        }
    }

    method associated_class ($class) {
        weaken($associated_class = $class)
            if $class;
        $associated_class;
    }
    method accessor_class { $self->associated_class->method_class }

    method constraint { $constraint }
    method reader     { $reader     }
    method writer     { $writer     }
    method accessor   { $accessor   }
    method predicate  { $predicate  }
    method clearer    { $clearer    }
    method init_arg   { $init_arg   }
    method builder    { $builder    }
    method lazy       { $lazy       }

    method has_constraint { defined $constraint }
    method has_reader     { defined $reader     }
    method has_writer     { defined $writer     }
    method has_accessor   { defined $accessor   }
    method has_predicate  { defined $predicate  }
    method has_clearer    { defined $clearer    }
    method has_init_arg   { defined $init_arg   }
    method has_builder    { defined $builder    }

    method _create_default_generator {
        my $get_default;
        # XXX actual defaults are always set in the constructor, not sure
        # what the best way around this is
        # if (defined $self->get_initial_value) {
        #     $get_default = sub { $self->get_initial_value_for_instance };
        # }
        if ($self->has_builder) {
            my $builder = $self->builder;
            $get_default = sub { shift->$builder };
        }
        else {
            $get_default = sub { undef };
        }
        $get_default;
    }
    method _create_validator {
        if (defined $constraint) {
            return sub { $constraint->validate($_[0]) };
        }
        else {
            return sub { 1 };
        }
    }

    method create_reader {
        my $slot = $self->get_name;
        my $validator = $self->_create_validator;
        if ($self->lazy) {
            my $get_default = $self->_create_default_generator;
            $self->accessor_class->new(
                name => $self->reader,
                body => sub {
                    my $val = mop::internal::instance::get_slot_at(
                        $::SELF, $slot
                    );
                    if (!defined($val)) {
                        $val = $get_default->($::SELF);
                        $validator->($val);
                        mop::internal::instance::set_slot_at(
                            $::SELF, $slot, \$val
                        );
                    }
                    $val;
                },
            );
        }
        else {
            $self->accessor_class->new(
                name => $self->reader,
                body => sub {
                    mop::internal::instance::get_slot_at($::SELF, $slot);
                },
            );
        }
    }
    method create_writer {
        my $slot = $self->get_name;
        my $validator = $self->_create_validator;
        $self->accessor_class->new(
            name => $self->writer,
            body => sub {
                my $val = shift;
                $validator->($val);
                mop::internal::instance::set_slot_at($::SELF, $slot, \$val);
            },
        );
    }
    method create_accessor {
        my $slot = $self->get_name;
        my $validator = $self->_create_validator;
        if ($self->lazy) {
            my $get_default = $self->_create_default_generator;
            $self->accessor_class->new(
                name => $self->accessor,
                body => sub {
                    if (@_) {
                        my $val = shift;
                        $validator->($val);
                        mop::internal::instance::set_slot_at(
                            $::SELF, $slot, \$val
                        );
                    }
                    my $val = mop::internal::instance::get_slot_at(
                        $::SELF, $slot
                    );
                    if (!defined($val)) {
                        $val = $get_default->($::SELF);
                        $validator->($val);
                        mop::internal::instance::set_slot_at(
                            $::SELF, $slot, \$val
                        );
                    }
                    $val;
                },
            );
        }
        else {
            $self->accessor_class->new(
                name => $self->accessor,
                body => sub {
                    if (@_) {
                        my $val = shift;
                        $validator->($val);
                        mop::internal::instance::set_slot_at(
                            $::SELF, $slot, \$val
                        );
                    }
                    mop::internal::instance::get_slot_at($::SELF, $slot);
                },
            );
        }
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

    method add_attribute ($attribute) {
        super($attribute);
        $attribute->associated_class($self);
    }

    method add_method ($method) {
        super($method);
        $method->associated_class($self);
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
                my ($params) = @_;

                for my $param (keys %$params) {
                    # XXX init_arg
                    my $attr = $::CLASS->find_attribute('$' . $param);
                    next unless $attr && $attr->isa(Attribute);
                    $attr->constraint->validate($params->{$param})
                        if $attr->has_constraint;
                }

                mop::WALKCLASS(
                    $dispatcher,
                    sub {
                        my $c = shift;
                        my $attributes = $c->get_attributes;
                        for my $attr (values %$attributes) {
                            next unless $attr->isa(Attribute);
                            next unless $attr->has_builder;
                            next if $attr->lazy;
                            next if defined mop::internal::instance::get_slot_at(
                                $instance, $attr->get_name
                            );

                            my $builder = $attr->builder;
                            my $initial_value = $instance->$builder;
                            $attr->constraint->validate($initial_value)
                                if $attr->has_constraint;
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
