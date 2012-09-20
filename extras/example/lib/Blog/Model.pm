use v5.16;
use mop;

use JSON::XS ();

use Blog::Model::Schema;

class Blog::Model {
    has $blog;
    has $storage;
    has $serializer = JSON::XS->new->pretty;

    method add_new_post ( $author, $title, $url, $body ) {
        $blog->add_post(
            Blog::Model::Schema::Post->new(
                author => Blog::Model::Schema::Author->new( name => $author ),
                title  => $title,
                url    => $url,
                body   => $body
            )
        );
    }

    method save {
        $storage->spew( $serializer->encode( $blog->pack ) )
    }

    method load {
        if ( -e $storage ) {
            $blog = $serializer->decode( $storage->slurp( chomp => 1 ) );
        }
        else {
            $blog = Blog::Model::Schema::Blog->new
        }
    }
}

1;



