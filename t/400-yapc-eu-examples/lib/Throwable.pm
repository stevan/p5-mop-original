use strict;
use warnings;
use mop;

use Devel::StackTrace;

class Throwable {

    has $message     = 'Error';
    has $stack_trace = Devel::StackTrace->new(
        frame_filter => sub {
            $_[0]->{'caller'}->[3] !~ /^mop\:\:/ &&
            $_[0]->{'caller'}->[0] !~ /^mop\:\:/ &&
            $_[0]->{'caller'}->[3] !~ /^Try\:\:/ &&
            $_[0]->{'caller'}->[0] !~ /^Try\:\:/
        }
    );

    method message     { $message     }
    method stack_trace { $stack_trace }
    method throw       { die $self    }

    method format_message ( $message ) { "$message" }
    method as_string {
        $self->format_message( $message )
            . "\n"
            . $stack_trace->as_string
    }
}

1;