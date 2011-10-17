use strict;
use warnings;
use mop;

use IO::Handle;

class Test::Builder::Output {
    has $output;
    has $error_output;

    BUILD {
        $output = IO::Handle->new;
        $output->fdopen( fileno( STDOUT ),"w" );

        $error_output = IO::Handle->new;
        $error_output->fdopen( fileno( STDERR ),"w" );
    }

    method write ( $message ) {
        $message =~ s/\n(?!#)/\n# /g;
        $output->print( $message, "\n" );
    }

    method diag ( $message ) {
        $message =~ s/^(?!#)/# /;
        $message =~ s/\n(?!#)/\n# /g;
        $output->print( $message, "\n" );
    }
}

1;