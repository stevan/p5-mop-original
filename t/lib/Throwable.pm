use mop;
use Devel::StackTrace;

class Throwable {

    has $message     = '';
    has $stack_trace = Devel::StackTrace->new(
        frame_filter => sub {
            $_[0]->{'caller'}->[3] !~ /^mop\:\:/ &&
            $_[0]->{'caller'}->[0] !~ /^mop\:\:/
        }
    );

    method message     { $message     }
    method stack_trace { $stack_trace }
    method throw       { die $self    }
    method as_string   { $message . "\n\n" . $stack_trace->as_string }
}

1;