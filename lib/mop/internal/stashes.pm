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
our @EXPORT_OK = qw(get_stash_for apply_overloading_for_stash);

sub get_stash_for {
    state $VTABLES = {};
    my $class = shift;
    $VTABLES->{ get_uuid($class) } //= _create_stash_for( $class );
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

# XXX used by FINALIZE, but moved here because we need to hardcode some things
# that FINALIZE does when bootstrapping... find a better way to do this maybe?
sub generate_DESTROY {
    return sub {
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
}

sub _create_stash_for {
    my ($class) = @_;
    my $stash = Package::Anon->new(${ get_slot_at( $class, '$name' ) } || ());
    apply_overloading_for_stash($stash);
    return $stash;
}

1;
