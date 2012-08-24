package mop::internal;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use mop::internal::instance;

use overload ();
use Package::Anon;
use PadWalker ();
use Scalar::Util ();
use Scope::Guard 'guard';
use version ();

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

    $version = version->parse($version)
        if defined $version;

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

## ...

sub _apply_overloading {
    my ($stash) = @_;

    # enable overloading
    {
        no strict 'refs';
        local *__ANON__ = $stash;
        *{ "__ANON__::OVERLOAD" }{HASH}->{dummy}++;
    }
    $stash->add_method('()' => \&overload::nil);

    # fallback => 1
    *{ $stash->{'()'} } = \1;

    # overloaded operations
    $stash->add_method('(bool' => sub { 1 });
    $stash->add_method('(~~' => sub {
        my $self = shift;
        my ($other) = @_;
        return $other->DOES($self);
    });
    $stash->add_method('(""' => sub { overload::StrVal($_[0]) });
    $stash->add_method('(0+' => sub { Scalar::Util::refaddr($_[0]) });
}

sub create_stash_for {
    my ($class) = @_;
    my $stash = Package::Anon->new( mop::internal::instance::get_slot_at( $class, '$name' ) );
    _apply_overloading($stash);
    return $stash;
}

sub get_stash_for {
    state $VTABLES = {};
    my $class = shift;
    my $uuid  = mop::internal::instance::get_uuid( $class );
    $VTABLES->{ $uuid } //= create_stash_for( $class );
}

sub execute_method {
    state $STACKS = {};

    my $method   = shift;
    my $invocant = shift;
    my $class    = mop::internal::instance::get_class( $invocant );
    my $instance = mop::internal::instance::get_slots( $invocant );
    my $body     = mop::internal::instance::get_slot_at( $method, '$body' );
    my $env      = {
        %$instance,
        '$self'  => \$invocant,
        '$class' => \$class
    };

    $STACKS->{ mop::uuid_of( $method ) } = []
        unless ref $STACKS->{ mop::uuid_of( $method ) };

    push @{ $STACKS->{ mop::uuid_of( $method ) } } => $env;
    PadWalker::set_closed_over( $body, $env );

    my $g = guard {
        my $stack = $STACKS->{ mop::uuid_of( $method ) };
        pop @$stack;
        my $env = $stack->[-1];
        if ( $env ) {
            PadWalker::set_closed_over( $body, $env );
        }
        else {
            PadWalker::set_closed_over( $body, {
                (map { $_ => \undef } keys %$instance),
                '$self'  => \undef,
                '$class' => \undef,
            });
        }
    };

    # localize the global invocant,
    # caller and class variables here
    local $::SELF   = $invocant;
    local $::CLASS  = $class;
    local $::CALLER = $method;

    $body->( @_ );
}

1;

__END__

=pod

=head1 NAME

mop::internal - The internals of the p5-mop

=head1 DESCRIPTION

This module contains some internal functions that
are mostly used in the bootstraping process. It is
here were most of the dragons lie, be not afraid,
this will not be the final implementation.

=head1 AUTHORS

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

Jesse Luehrs E<lt>doy at tozt dot netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut