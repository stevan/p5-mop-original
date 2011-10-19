package mop::internal::class;

use strict;
use warnings;

use mop::internal::instance;
use mop::internal::role;

sub create {
    my %params = @_;

    my $class        = $params{'class'}        || die "A class must have a (meta) class";
    my $name         = $params{'name'}         || die "A class must have a name";
    my $version      = $params{'version'}      || undef;
    my $authority    = $params{'authority'}    || '';
    my $superclasses = $params{'superclasses'} || [];
    my $roles        = $params{'roles'}        || [];
    my $attributes   = $params{'attributes'}   || {};
    my $methods      = $params{'methods'}      || {};
    my $constructor  = $params{'constructor'}  || undef;
    my $destructor   = $params{'destructor'}   || undef;

    mop::internal::instance::create(
        $class,
        {
            '$name'         => \$name,
            '$version'      => \$version,
            '$authority'    => \$authority,
            '$superclasses' => \$superclasses,
            '$roles'        => \$roles,
            '$attributes'   => \$attributes,
            '$methods'      => \$methods,
            '$constructor'  => \$constructor,
            '$destructor'   => \$destructor
        }
    );
}

# These two functions are needed by the internal::dispatchers

sub get_mro {
    my $class = shift;
    return [
        $class,
        (map {
            @{ get_mro( $_ ) }
        } grep {
            # Role does Role
            !equals( $_, $class )
        } @{ mop::internal::instance::get_slot_at( $class, '$roles' ) || [] }),
        (map {
            @{ get_mro( $_ ) }
        } @{ mop::internal::instance::get_slot_at( $class, '$superclasses' ) || [] }),
                # NOTE: the C<|| []> stuff fixes an issue during global destruction
    ]
}

sub find_method {
    my ($class, $method_name) = @_;
    mop::internal::instance::get_slot_at( $class, '$methods' )->{ $method_name };
}

sub get_constructor {
    my $class = shift;
    mop::internal::instance::get_slot_at( $class, '$constructor' );
}

sub get_destructor {
    my $class = shift;
    mop::internal::instance::get_slot_at( $class, '$destructor' );
}

sub is_subclass_of {
    my $class = shift;
    my ($super) = @_;

    return 1 if equals( $super, $::Object ) && !equals( $class, $::Object );

    my @mro = @{ get_mro($class) };
    shift @mro;
    # is_subclass_of should be false for roles
    @mro = grep { !equals( $super, $::Role ) && !is_subclass_of( $super, $::Role ) } @mro;
    return scalar grep { equals( $super, $_ ) } @mro;
}

sub equals {
    my $class = shift;
    my ($other) = @_;

    return mop::internal::instance::get_uuid($class) eq mop::internal::instance::get_uuid($other);
}

sub get_compatible_class {
    my @classes = @_;

    return unless @classes;

    my $compatible = shift @classes;
    for my $class ( @classes ) {
        if ( is_subclass_of( $class, $compatible ) ) {
            # replace the class with a subclass of itself
            $compatible = $class;
        }
        elsif ( is_subclass_of( $compatible, $class ) ) {
            # it's already okay
        }
        elsif ( equals( $class, $compatible ) ) {
            # it's already okay
        }
        else {
            # reconciling this group of metaclasses isn't possible
            return;
        }
    }

    return $compatible;
}

1;

__END__

=pod

=head1 NAME

mop::internal::class

=head1 DESCRIPTION

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut