use v5.16;
use mop;

use JSON::XS ();

use Blog::Model::Schema;

my $serializer = JSON::XS->new->pretty;

class Blog::Model {
    has $blog;
    has $storage;

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

    method txn_do ( $method, @args ) {
        $self->load;
        $self->$method( @args );
        $self->save;
    }

    method save {
        $storage->spew( $serializer->encode( $blog->pack ) )
    }

    method load {
        $blog = Blog::Model::Schema::Blog->new;
        if ( -e $storage ) {
            $blog->unpack( $serializer->decode( scalar $storage->slurp( chomp => 1 ) ) );
        }
    }
}

1;



