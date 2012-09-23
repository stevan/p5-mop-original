use v5.16;
use mop;

use Path::Class      qw[ file ];
use File::Temp       qw[ tempfile ];
use IO::Prompt::Tiny qw[ prompt ];

class Blog::Editor {
    has $command;

    method prompt ( $message, $default ) { prompt( $message, $default ) }

    method invoke ( $text ) {
        my ($fh, $filename) = tempfile;
        if ( $text ) {
            print $fh $text;
        }
        my $status = system( (ref $command ? @$command : $command), $filename );
        unless ( $status == 0 ) {
            # Stolen from Proc::InvokeEditor
            my ($exit_value, $signal_num, $dumped_core);
            $exit_value  = $? >> 8;
            $signal_num  = $? & 127;
            $dumped_core = $? & 128;
            die "Error in editor invocation: exit val = $exit_value, signal = $signal_num, coredump? = $dumped_core : $!";
        }
        return file( $filename )->slurp;
    }
}

1;