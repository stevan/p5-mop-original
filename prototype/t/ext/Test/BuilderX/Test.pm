package Test::BuilderX::Test;
use strict;
use warnings;
use mop;

use Params::Validate qw(:all);

sub new {
    shift;
    validate(
        @_, {
            number      => { type => SCALAR  },
            passed      => { type => BOOLEAN, default => 1  },
            skip        => { type => SCALAR,  default => 0  },
            todo        => { type => SCALAR,  default => 0  },
            reason      => { type => SCALAR,  default => '' },
            description => { type => SCALAR,  default => '' }
        }
    );
    my ($number, $passed, $skip, $todo, $reason, $description) = @_;

    return TODO->new(
        description => $description,
        passed      => $passed,
        reason      => $reason,
        number      => $number,
    ) if $todo;

    return Skip->new(
        description => $description,
        passed      => 1,
        reason      => $reason,
        number      => $number,
    ) if $skip;

    return Pass->new(
        description => $description,
        passed      => 1,
        number      => $number,
    ) if $passed;

    return Fail->new(
        description => $description,
        passed      => 0,
        number      => $number,
    );
}

BEGIN {
    class Base {

        has $passed;
        has $number;
        has $diagnostic;
        has $description;

        BUILD {
            $number     //= 0;
            $diagnostic //= '???';
        }

        method passed      { $passed      }
        method number      { $number      }
        method description { $description }

        method status {
            return +{ passed => $passed, description => $description }
        }

        method report {
            my $ok = $passed ? 'ok ' : 'not ok ';
            $ok .= $number;
            $ok .= " - $description" if $description;
            return $ok;
        }
    }

    class Pass ( extends => Base() ) {}
    class Fail ( extends => Base() ) {}

    class WithReason ( extends => Base() ) {
        has $reason;

        method reason { $reason }

        method status {
            my $status = $self->NEXTMETHOD;
            $status->{'reason'} = $reason;
            $status;
        }
    }

    class Skip ( extends => WithReason() ) {

        method report {
            return "not ok " . $self->number . " #skip " . $self->reason;
        }

        method status {
            my $status = $self->NEXTMETHOD;
            $status->{'skip'} = 1;
            $status;
        }
    }

    class TODO ( extends => WithReason() ) {

        method report {
            my $ok          = $self->passed ? 'ok' : 'not ok';
            my $description = "# TODO " . $self->description;
            return join ' ' => ( $ok, $self->number, $description );
        }

        method status {
            my $status = $self->NEXTMETHOD;
            $status->{'TODO'}          = 1;
            $status->{'passed'}        = 1;
            $status->{'really_passed'} = $self->passed;
            $status;
        }

    }

}

1;

