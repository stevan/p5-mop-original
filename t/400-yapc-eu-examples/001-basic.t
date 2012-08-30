#!perl

use v5.14;

use strict;
use warnings;

use Test::More;

use Test::Requires 'Devel::StackTrace';
use Test::Requires 'Try';
use Test::Requires 'Fun';
use Test::Requires 'Variable::Magic';
use Test::Requires 'Perl6::Junction';

use Scalar::Util 'blessed';
use File::Temp 'tempfile';
use Fun; use Try;

use lib 't/400-yapc-eu-examples/lib/';

package MyApp::IO {
    use strict;
    use warnings;
    use mop;
    use Fun;
    use GuardedAttribute;
    use Perl6::Junction qw[ any ];

    role FileInfo ( metaclass => GuardedAttributeRole ) {
        has $mode     ( guard => fun ($x) { $x eq any('r', 'w') } );
        has $filename ( guard => fun ($x) { defined $x } );
        method mode     { $mode     }
        method filename { $filename }
    }

    class FileHandle ( with => [FileInfo] ) {
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

        class FileNotFound ( with => [ Throwable, MyApp::IO::FileInfo ] ) {
            method format_message ( $message ) {
                "File '" . $self->filename . "' not found" . ($message ? ": $message" : '')
            }
        }

        class PermissionsError ( with => [ Throwable, MyApp::IO::FileInfo ] ) {
            method format_message ( $message ) {
                my $type = do {
                    given ( $self->mode ) {
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

my ($fh, $filename) = tempfile;

try {
    my $r = MyApp::IO::FileHandle->new( filename => $filename, mode =>'r' );
    my $x = 0;
    $r->iter_lines( fun ( $line ) {  chomp $line && say join ' ' => $x++, ':',  $line } );
    pass("... this worked");
} catch {
    fail("... this failed");
    when ( blessed $_ ) {
        warn $_->as_string;
    }
    default {
        warn $_;
    }
}

#unlink $filename;

done_testing;

