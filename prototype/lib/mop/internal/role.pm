package mop::internal::role;

use strict;
use warnings;

use mop::internal::instance;

sub create {
    my %params = @_;

    my $class        = $params{'class'}        || die "A role must have a (meta) class";
    my $name         = $params{'name'}         || die "A role must have a name";
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

1;
