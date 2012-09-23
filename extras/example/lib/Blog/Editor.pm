use v5.16;
use mop;

use Proc::InvokeEditor;
use IO::Prompt::Tiny qw[ prompt ];

class Blog::Editor {
    has $editors;

    method prompt ( $message, $default ) { prompt( $message, $default ) }

    method invoke ( $text ) {
        Proc::InvokeEditor->new( editors => $editors )->edit( $text // () );
    }
}

1;