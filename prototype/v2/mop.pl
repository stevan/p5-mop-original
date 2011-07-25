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
        ${ $instance->{'data'}->{ $name } || \undef }
    }
}

{
    package mop::dispatchable;
    use strict;
    use warnings;
    use PadWalker ();

    sub WALKMETH {
        my ($class, $method_name) = @_;
        WALKCLASS( $class, sub { mop::instance::get_data_at( $_[0], '$methods' )->{ $method_name } } );
    }

    sub WALKCLASS {
        my ($class, $solver) = @_;
        if ( my $result = $solver->( $class ) ) {
            return $result;
        }
        foreach my $super ( @{ mop::instance::get_data_at( $class, '$superclasses' ) } ) {
            if ( my $result = WALKCLASS( $super, $solver ) ) {
                return $result;
            }
        }
    }

    sub DISPATCH {
        my $method_name = shift;
        my $invocant    = shift;
        my $class       = mop::instance::get_class( $invocant );
        my $method      = WALKMETH( $class, $method_name ) || die "Could not find method '$method_name'";
        my $instance    = mop::instance::get_data( $invocant );

        PadWalker::set_closed_over( $method, {
            %$instance,
            '$self'  => \$invocant,
            '$class' => \$class
        });

        local $::SELF  = $invocant;
        local $::CLASS = $class;

        $method->( @_ );
    }

    sub AUTOLOAD {
        my @autoload    = (split '::', our $AUTOLOAD);
        my $method_name = $autoload[-1];
        return if $method_name eq 'DESTROY';

        DISPATCH( $method_name, @_ );
    }
}

## ------------------------------------------------------------------

my $Class;

$Class = mop::instance::create(
    \$Class,
    {
        '$superclasses' => \[],
        '$attributes'   => \{},
        '$methods'      => \{
            'get_superclasses' => sub { mop::instance::get_data_at( $::SELF, '$superclasses' ) },
            'get_methods'      => sub { mop::instance::get_data_at( $::SELF, '$methods' )      },
            'get_attributes'   => sub { mop::instance::get_data_at( $::SELF, '$attributes' )   },
        }
    }
);

my $Object = mop::instance::create(
    \$Class,
    {
        '$superclasses' => \[],
        '$attributes'   => \{},
        '$methods'      => \{
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
            },
            'id'    => sub { mop::instance::get_uuid( $::SELF ) },
            'class' => sub { mop::instance::get_class( $::SELF ) },
        }
    }
);

mop::instance::get_data_at( $Class, '$superclasses' )->[0] = $Object;

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

    my $meta = {
        'methods'      => {},
        'superclasses' => [],
    };

    my $attrs = PadWalker::peek_sub( $body );
    delete $attrs->{'$self'};
    delete $attrs->{'$class'};

    $meta->{'attributes'} = $attrs;

    $body->();

    push @{ $meta->{'superclasses'} } => $Object
        unless scalar @{ $meta->{'superclasses'} };

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

like $Point->id, qr/[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}/, '... got the expected uuid format';
is $Point->class, $Class, '... got the class we expected';
is_deeply $Point->get_superclasses, [ $Object ], '... got the superclasses we expected';

## Test an instance

my $p = $Point->new( x => 100, y => 320 );

like $p->id, qr/[0-9A-Z]{8}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{12}/, '... got the expected uuid format';
is $p->class, $Point, '... got the class we expected';

is $p->x, 100, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 100, y => 320 }, '... got the right value from dump';

$p->set_x(10);
is $p->x, 10, '... got the right value for x';

is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

my $p2 = $Point->new( x => 1, y => 30 );

isnt $p->id, $p2->id, '... not the same instances';

is $p2->x, 1, '... got the right value for x';
is $p2->y, 30, '... got the right value for y';
is_deeply $p2->dump, { x => 1, y => 30 }, '... got the right value from dump';

$p2->set_x(500);
is $p2->x, 500, '... got the right value for x';
is_deeply $p2->dump, { x => 500, y => 30 }, '... got the right value from dump';

is $p->x, 10, '... got the right value for x';
is $p->y, 320, '... got the right value for y';
is_deeply $p->dump, { x => 10, y => 320 }, '... got the right value from dump';

done_testing;



















