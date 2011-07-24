#!perl

use strict;
use warnings;

use PadWalker ();

use Test::More;

our ($SELF, $CLASS);

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

    sub get_uuid  { (shift)->{'uuid'}     }
    sub get_class { ${(shift)->{'class'}} }
    sub get_data  { (shift)->{'data'}     }
    sub get_data_at {
        my ($instance, $name) = @_;
        ${ $instance->{'data'}->{ $name } }
    }
}

{
    package mop::dispatchable;
    use strict;
    use warnings;
    use PadWalker ();

    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        my $invocant = shift;
        my $class    = mop::instance::get_class( $invocant );
        my $method   = mop::instance::get_data_at( $class, '$methods' )->{ $method_name };
        my $instance = mop::instance::get_data( $invocant );

        PadWalker::set_closed_over( $method, {
            %$instance,
            '$self'  => \$invocant,
            '$class' => \$class
        });

        local $::SELF  = $invocant;
        local $::CLASS = $class;

        $method->( @_ );
    }
}

## ------------------------------------------------------------------

my $Class;

$Class = mop::instance::create(
    \$Class,
    {
        '$methods' => \{
            'new' => sub {
                my %args  = @_;

                my $instance = {};
                foreach my $arg ( keys %args ) {
                    my $value = $args{ $arg };
                    $instance->{ '$' . $arg } = \$value;
                }

                return mop::instance::create(
                    \$::SELF,
                    $instance
                );
            }
        }
    }
);

## ------------------------------------------------------------------

sub method {
    my ($name, $body) = @_;
    my $pad = PadWalker::peek_my(2);
    ${$pad->{'$meta'}}->{'methods'}->{ $name } = $body;
}

sub extends {
    my ($superclass) = @_;
    my $pad = PadWalker::peek_my(2);
    push @{ ${$pad->{'$meta'}}->{'superclasses'} } => $superclass;
}

## This is where most of the work is done
sub class (&) {
    my $body = shift;

    my $meta = {};

    my $attrs = PadWalker::peek_sub( $body );
    delete $attrs->{'$self'};
    delete $attrs->{'$class'};

    $meta->{'attributes'} = $attrs;

    $body->();

    $Class->new( %$meta );
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



















