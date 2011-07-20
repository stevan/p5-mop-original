package mop::method;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;
    bless {
        name     => $params{'name'},
        metadata => $params{'metadata'},
        body     => $params{'body'}
    } => $class;
}

sub name       { (shift)->{'name'}     }
sub metadata   { (shift)->{'metadata'} }
sub body       { (shift)->{'body'}     }

1;

__END__

=pod

=cut