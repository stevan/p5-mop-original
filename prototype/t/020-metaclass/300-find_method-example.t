#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
BEGIN { undef *note }

use mop;

=pod

Example stolen from http://6guts.wordpress.com/2011/08/01/a-hint-of-meta-programming/

=cut

my @NOTES;
sub note { push @NOTES, $_[0] }

BEGIN {
    package LoggedDispatch;
    use mop;

    class LoggedDispatch (extends => $::Class) {
        method find_method ($name) {
            ::note "Looking up method $name";
            super($name);
        }
        method FINALIZE {
            # there is no fallback dispatching if our method cache doesn't exist,
            # so we need to install one instead of just leaving it empty
            # this may change in the future

            # still need to set up things like base classes
            super;

            my $stash = mop::internal::get_stash_for($self);
            %$stash = (DESTROY => $stash->{DESTROY});
            $stash->add_method(AUTOLOAD => sub {
                (my $name = our $AUTOLOAD) =~ s/.*:://;
                $self->find_method($name)->execute(@_);
            });
        }
    }

    sub import {
        mop->import(-metaclass => LoggedDispatch);
    }

    $INC{'LoggedDispatch.pm'} = 1;
}

{
    use LoggedDispatch;

    class A {
        method m1 { note "42" }
        method m2 { note "99" }
    }

    for (1..2) {
        my $a = A->new;
        $a->m1;
        $a->m2;
    }

    is_deeply([@NOTES], [
        # no BUILD showing up here, because that's a perl 6 implementation detail
        'Looking up method m1',
        '42',
        'Looking up method m2',
        '99',
        'Looking up method m1',
        '42',
        'Looking up method m2',
        '99',
    ]);
}

done_testing;
