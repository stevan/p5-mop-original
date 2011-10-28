package mop::internal;

use strict;
use warnings;

use mop::internal::instance;

use PadWalker ();
use Scope::Guard 'guard';

sub create_class {
    my %params = @_;

    my $class       = $params{'class'}       || die "A class must have a (meta) class";
    my $name        = $params{'name'}        || die "A class must have a name";
    my $version     = $params{'version'}     || undef;
    my $authority   = $params{'authority'}   || '';
    my $superclass  = $params{'superclass'}  || undef;
    my $attributes  = $params{'attributes'}  || {};
    my $methods     = $params{'methods'}     || {};
    my $constructor = $params{'constructor'} || undef;
    my $destructor  = $params{'destructor'}  || undef;
    my $dispatcher  = $params{'dispatcher'}  || undef;

    mop::internal::instance::create(
        $class,
        {
            '$name'        => \$name,
            '$version'     => \$version,
            '$authority'   => \$authority,
            '$superclass'  => \$superclass,
            '$attributes'  => \$attributes,
            '$methods'     => \$methods,
            '$constructor' => \$constructor,
            '$destructor'  => \$destructor,
            '$dispatcher'  => \$dispatcher,
        }
    );
}

sub create_attribute {
    my %params = @_;

    my $name          = $params{'name'}          || die "An attribute must have a name";
    my $initial_value = $params{'initial_value'} || undef;

    mop::internal::instance::create(
        \$::Attribute,
        {
            '$name'          => \$name,
            '$initial_value' => \$initial_value,
        }
    );
}

sub create_method {
    my %params = @_;

    my $name = $params{'name'} || die "A method must have a name";
    my $body = $params{'body'} || die "A method must have a body";

    mop::internal::instance::create(
        \$::Method,
        {
            '$name' => \$name,
            '$body' => \$body,
        }
    );
}

sub create_dispatcher {
    my %params = @_;

    my $class = $params{'class'} || die "A dispatcher must have a class";

    mop::internal::instance::create(
        \$::Dispatcher,
        {
            '$class' => \$class,
        }
    );
}

## ...

sub execute_method {
    my $method   = shift;
    my $invocant = shift;
    my $class    = mop::internal::instance::get_class( $invocant );
    my $instance = mop::internal::instance::get_slot( $invocant );
    my $body     = mop::internal::instance::get_slot_at( $method, '$body' );

    PadWalker::set_closed_over( $body, {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class
    });

    my $g = guard {
        PadWalker::set_closed_over( $body, {
            (map { $_ => \undef } keys %$instance),
            '$self'  => \undef,
            '$class' => \undef,
        });
    };

    # localize the global invocant
    # and class variables here
    local $::SELF  = $invocant;
    local $::CLASS = $class;

    $body->( @_ );
}

1;

__END__

=pod

=head1 NAME

mop::internal

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut