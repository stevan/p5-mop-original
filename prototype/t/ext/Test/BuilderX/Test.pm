package Test::BuilderX::Test;
use strict;
use warnings;
use mop;

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

class Pass ( extends => Base ) {}
class Fail ( extends => Base ) {}

class WithReason ( extends => Base ) {
    has $reason;

    method reason { $reason }

    method status {
        my $status = super;
        $status->{'reason'} = $reason;
        $status;
    }
}

class Skip ( extends => WithReason ) {

    method report {
        return "not ok " . $self->number . " #skip " . $self->reason;
    }

    method status {
        my $status = super;
        $status->{'skip'} = 1;
        $status;
    }
}

class TODO ( extends => WithReason ) {

    method report {
        my $ok          = $self->passed ? 'ok' : 'not ok';
        my $description = "# TODO " . $self->description;
        return join ' ' => ( $ok, $self->number, $description );
    }

    method status {
        my $status = super;
        $status->{'TODO'}          = 1;
        $status->{'passed'}        = 1;
        $status->{'really_passed'} = $self->passed;
        $status;
    }
}

sub new {
    shift;
    my %params = @_;
    my ($number, $passed, $skip, $todo, $reason, $description) = @params{qw[
        number
        passed
        skip
        todo
        reason
        description
    ]};

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

1;

