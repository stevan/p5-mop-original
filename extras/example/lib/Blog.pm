use v5.16;
use mop;

use Path::Class qw[ file ];

use Blog::Model;
use Blog::Logger;

class Blog {
    has $logger;
    has $model;

    BUILD {
        $logger = Blog::Logger->new;
        $model  = Blog::Model->new( storage => file( './data.json' ) );
    }

    method process_options ( $cmd, @args ) {

        warn $logger;
        warn $model;

        if ( $cmd eq 'new-post') {

            $model->load;
            $model->add_new_post( @args );
            $model->save;

            $logger->log( info => 'Creating new post' );
        }
        else {
            $logger->log( error => 'No command specified' );
            exit;
        }
    }
}

1;