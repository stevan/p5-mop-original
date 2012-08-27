#!perl

use v5.14;

use strict;
use warnings;

BEGIN {
    eval { require Devel::StackTrace; 1 }
    or plan skip_all => "Devel::StackTrace is required for this test";

    eval { require Try; 1 }
    or plan skip_all => "Try is required for this test";

    eval { require Fun; 1 }
    or plan skip_all => "Fun is required for this test";

    eval { require Variable::Magic; 1 }
    or plan skip_all => "Variable::Magic is required for this test";

    eval { require Perl6::Junction; 1 }
    or plan skip_all => "Perl6::Junction is required for this test";
}

use Test::More;
use Scalar::Util 'blessed';
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

    class FileHandle ( with => FileInfo ) {
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

