package mop::internal::stashes;

use 5.014;
use strict;
use warnings;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:STEVAN';

use overload ();
use Package::Anon;
use Scalar::Util qw(refaddr);

use mop::internal::instance qw(get_uuid get_class get_slot_at);
use mop::util;

use Exporter 'import';
our @EXPORT_OK = qw(get_stash_for populate_stash);

sub get_stash_for {
    state $VTABLES = {};
    my $class = shift;
    $VTABLES->{ get_uuid($class) } //= _create_stash_for( $class );
}

sub populate_stash {
    my ($stash, $methods, $params) = @_;
    $params //= {};

    %$stash = ();

    foreach my $name ( keys %$methods ) {
        my $method = $methods->{ $name };
        $stash->add_method(
            $name,
            ($params->{bootstrap}
                ? sub { mop::internal::execute_method($method, @_) }
                : $method->_generate_callable_sub)
        );
    }

    $stash->add_method(
        'DESTROY' => sub {
            my $invocant = shift;

            my $class = get_class( $invocant );
            return unless $class; # likely in global destruction ...

            mop::util::WALKCLASS(
                $class->dispatcher(),
                sub {
                    my $dispatcher = $_[0]->destructor;
                    return unless $dispatcher;
                    $dispatcher->execute($invocant);
                    return;
                }
            );
        }
    );

    apply_overloading_for_stash($stash);
}

sub apply_overloading_for_stash {
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
    $stash->add_method('(0+' => sub { refaddr($_[0]) });
    $stash->add_method('(==' => sub { get_uuid($_[0]) eq get_uuid($_[1]) });
}

sub _create_stash_for {
    my ($class) = @_;
    return Package::Anon->new(${ get_slot_at( $class, '$name' ) } || ());
}

1;
