package Test::BuilderX::Test;
use strict;
use warnings;
use mop;

role Base {

    has $passed;
    has $number     = 0;
    has $diagnostic = '???';
    has $description;

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

class Pass ( with => [Base] ) {}
class Fail ( with => [Base] ) {}

role WithReason ( with => [Base] ) {
    has $reason;

    method reason { $reason }

    method status {
        # FIXME
        my $status = Base->find_method('status')->execute( $self );
        $status->{'reason'} = $reason;
        $status;
    }
}

class Skip ( with => [WithReason] ) {

    method report {
        return "not ok " . $self->number . " #skip " . $self->reason;
    }

    method status {
        # FIXME
        my $status = WithReason->find_method('status')->execute( $self );
        $status->{'skip'} = 1;
        $status;
    }
}

class TODO ( with => [WithReason] ) {

    method report {
        my $ok          = $self->passed ? 'ok' : 'not ok';
        my $description = "# TODO " . $self->description;
        return join ' ' => ( $ok, $self->number, $description );
    }

    method status {
        # FIXME
        my $status = WithReason->find_method('status')->execute( $self );
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

