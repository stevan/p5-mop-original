use v5.16;
use mop;

class Blog::Logger {
    method log ( $level, $msg ) {
        given ( $level ) {
            when ( 'info'  ) { warn $msg }
            when ( 'warn'  ) { warn $msg }
            when ( 'error' ) { warn $msg }
            when ( 'fatal' ) { die  $msg }
            default {
                die "bad logging level: $level"
            }
        }
    }
}

1;