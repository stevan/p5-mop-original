#!perl

use strict;
use warnings;

use Test::More;

use PadWalker;

my ($self, $class);

{
    package mop::instance;
    use strict;
    use warnings;
    use Data::UUID;

    my $UUID = Data::UUID->new;

    sub create {
        my ($class, $data) = @_;
        bless {
            uuid  => $UUID->create_str,
            class => $class,
            data  => $data
        } => 'mop::dispatchable';
    }
}

{
    package mop::dispatchable;
    use strict;
    use warnings;
    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        my $invocant = shift;
        my $class    = $invocant->{'class'};
        my $method   = $class->{'%methods'}->{ $method_name };
        my $instance = $invocant->{'data'};

        PadWalker::set_closed_over( $method, {
            %$instance,
            '$self'  => \$invocant,
        });

        $method->( @_ );
    }
}

sub method {
    my ($name, $body) = @_;
    my $pad = PadWalker::peek_my(2);
    ${$pad->{'$meta'}}->{'%methods'}->{ $name } = $body;
}

sub extends {
    my ($superclass) = @_;
    my $pad = PadWalker::peek_my(2);
    push @{ ${$pad->{'$meta'}}->{'@superclasses'} } => $superclass;
}

## This is where most of the work is done
sub class (&) {
    my $body = shift;

    my $meta = {};

    my $attrs = PadWalker::peek_sub( $body );
    delete $attrs->{'$self'};
    delete $attrs->{'$class'};

    $meta->{'%attributes'} = $attrs;

    $body->();

    mop::instance::create(
        {
            '%methods' => {
                'new' => sub {
                    my %args = @_;

                    my $instance = {};
                    foreach my $arg ( keys %args ) {
                        my $value = $args{ $arg };
                        $instance->{ '$' . $arg } = \$value;
                    }

                    return mop::instance::create(
                        $meta,
                        $instance
                    );
                }
            }
        },
        $meta
    );
}

# -------------------------------------------------------------------

my $Point = class {
    my $x;
    my $y;

    method 'x' => sub { $x };
    method 'y' => sub { $y };

    method 'set_x' => sub {
        my $new_x = shift;
        $x = $new_x;
    };

    method 'dump' => sub {
        +{ x => $self->x, y => $self->y }
    };
};

## Test the class

my $p = $Point->new( x => 100, y => 320 );

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

done_testing;



















