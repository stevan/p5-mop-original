package mop::class;

use strict;
use warnings;

sub new {
    my ($class, %params) = @_;
    bless {
        name       => $params{'name'},
        metadata   => $params{'metadata'},
        attributes => [],
        methods    => []
    } => $class;
}

sub name       { (shift)->{'name'}       }
sub metadata   { (shift)->{'metadata'}   }
sub attributes { (shift)->{'attributes'} }
sub methods    { (shift)->{'methods'}    }

sub add_attribute {
    my ($self, $attribute) = @_;
    push @{ $self->{'attributes'} } => $attribute;
}

sub add_method {
    my ($self, $method) = @_;
    push @{ $self->{'methods'} } => $method;
}

1;

__END__

=pod

=cut