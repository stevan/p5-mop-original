use v5.16;
use mop;

use Try;
use Path::Class qw[ file ];

use Blog::Model;
use Blog::Logger;

class Blog {
    has $logger = Blog::Logger->new;
    has $model  = Blog::Model->new( storage => file( './data.json' ) );

    method run ( @arg ) {
        try {
            $self->handle_options( @args );
            exit;
        } catch {
            $logger->log( fatal => 'An error occurred: ' . $_ );
            exit(1);
        }
    }

    method handle_options ( $cmd, @args ) {
        given ( $cmd ) {
            when ( 'new-post') {
                $model->txn_do( add_new_post => @args );
                $logger->log( info => 'Creating new post' );
            }
            default {
                $logger->log( error => 'No command specified' );
            }
        }
    }
}

1;