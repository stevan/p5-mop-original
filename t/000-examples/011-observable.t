#!perl

use v5.14;

use Test::More;
use Test::Fatal;

use mop;

role Observable {
    has %callbacks;

    method bind ( $name, $callback ) {
        $callbacks{ $name } = [] unless exists $callbacks{ $name };
        push @{ $callbacks{ $name } } => $callback;
        $self;
    }

    method trigger ( $name, @args ) {
        return $self unless exists $callbacks{ $name };
        map { $_->( @args ) } @{ $callbacks{ $name } };
        $self;
    }
}

class FooWatcher ( roles => [Observable]) {}

my (@FOO, @BAR);

my $o = FooWatcher->new;
ok($o->isa(FooWatcher), '... isa FooWatcher');

TODO: { todo_skip "instance_does not yet implemented", 3 if $ENV{PERL_MOP_MINI};
ok($o->does(Observable), '... does Observable');
ok($o->DOES(FooWatcher), '... DOES FooWatcher');
ok($o->DOES(Observable), '... DOES Observable');
}

is(exception { $o->bind( 'foo' => sub { push @FOO => @_ } ) }, undef, '... bind succeeded');
is(exception { $o->bind( 'foo' => sub { push @BAR => 1  } ) }, undef, '... bind succeeded');

is(exception { $o->trigger( 'foo' => ( 'bar' ) ) }, undef, '... trigger succeeded');

is_deeply(\@FOO, [ 'bar' ], '... got the right values');
is_deeply(\@BAR, [ 1 ], '... got the right values');

is(exception { $o->trigger( 'foo' => ( 'baz' ) ) }, undef, '... trigger succeeded');

is_deeply(\@FOO, [ 'bar', 'baz' ], '... got the right values');
is_deeply(\@BAR, [ 1, 1 ], '... got the right values');

done_testing;

