package mop::attribute;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;
    bless {
        name     => $params{'name'},
        metadata => $params{'metadata'},
    } => $class;
}

sub name       { (shift)->{'name'}     }
sub metadata   { (shift)->{'metadata'} }

1;

__END__

=pod

=cut