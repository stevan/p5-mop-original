use v5.16;
use mop;

use Try;
use Path::Class qw[ file ];

use Blog::Config;
use Blog::Model;
use Blog::Logger;
use Blog::Editor;

class Blog {
    has $config = Blog::Config->new;
    has $logger;
    has $model;

    BUILD {
        $logger = Blog::Logger->new;
        $model  = Blog::Model->new(
            storage => file( $config->get('storage') ),
            editor  => Blog::Editor->new( editors => $config->get('editors') )
        )
    }

    method run ( @args ) {
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
            when ( 'edit-post') {
                $model->txn_do( edit_post => @args );
                $logger->log( info => 'Editing post' );
            }
            default {
                $logger->log( error => 'No command specified' );
            }
        }
    }
}

1;