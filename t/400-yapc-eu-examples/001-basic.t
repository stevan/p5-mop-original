#!perl

use v5.14;

use strict;
use warnings;

use Test::More;
use Scalar::Util 'blessed';
use Fun; use Try;

use lib 't/400-yapc-eu-examples/lib/';

package MyApp::IO {
    use strict;
    use warnings;
    use mop;

    role HasFilenameAndMode {
        has $mode;
        has $filename;
        method mode     { $mode     }
        method filename { $filename }
    }

    class FileHandle ( with => HasFilenameAndMode ) {
        has $fh;

        BUILD ($params) {
            $fh = IO::File->new( $self->filename, $self->mode )
                or MyApp::IO::Util::convert_error( $!, $self );
        }

        method iter_lines ( $f ) {
            while ( my $line = $fh->getline ) {
                MyApp::IO::Util::convert_error( $!, $self )
                    if not defined $line;
                $f->( $line );
            }
            $fh->seek( 0, 0 );
            $self;
        }

        method slurp {
            $fh->read( my $x, -s $fh )
                or MyApp::IO::Util::convert_error( $!, $self );
            $x;
        }

        DEMOLISH {
            $fh->close or MyApp::IO::Util::convert_error( $!, $self )
                if $fh;
        }
    }

    package MyApp::IO::Error {
        use strict;
        use warnings;
        use mop;

        use Throwable;

        class FileNotFound ( extends => Throwable, with => MyApp::IO::HasFilenameAndMode ) {
            method format_message ( $message ) {
                "File '" . $self->filename . "' not found" . ($message ? ": $message" : '')
            }
        }

        class PermissionsError ( extends => Throwable, with => MyApp::IO::HasFilenameAndMode ) {
            method format_message ( $message ) {
                my $type = do {
                    given ($self->mode ) {
                        when ('r') { 'readable' }
                        when ('w') { 'writeable' }
                    }
                };
                "File '" . $self->filename . "' is not '$type'" . ($message ? ": $message" : '')
            }
        }
    }

    package MyApp::IO::Util {
        use strict;
        use warnings;
        use Fun;

        fun convert_error ($err, $handle) {
            given ( $err ) {
                when ( 'No such file or directory' ) {
                    MyApp::IO::Error::FileNotFound->new(
                        filename => $handle->filename
                    )->throw
                }
                when ( 'Permission denied' ) {
                    MyApp::IO::Error::PermissionsError->new(
                        filename => $handle->filename,
                        mode     => $handle->mode
                    )->throw
                }
                default {
                    warn $err if $err;
                }
            }
        }
    }
}


try {
    my $r = MyApp::IO::FileHandle->new( filename => 'foo', mode =>'r' );
    my $x = 0;
    $r->iter_lines( fun ( $line ) {  chomp $line && say join ' ' => $x++, ':',  $line } );
} catch {
    when ( blessed $_ ) {
        warn $_->as_string;
    }
    default {
        warn $_;
    }
}

done_testing;

