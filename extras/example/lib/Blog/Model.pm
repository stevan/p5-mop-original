use v5.16;
use mop;

use Fun;
use JSON::XS ();
use Blog::Model::Schema;

my $serializer = JSON::XS->new->pretty;

class Blog::Model {
    has $blog;

    has $editor;
    has $storage;

    method add_new_post ( $author, $title, $url, $body ) {

        $author //= $editor->prompt('Author : ');
        $title  //= $editor->prompt('Title  : ');
        $url    //= $editor->prompt('URL    : ');
        $body   //= $editor->invoke;

        $blog->add_post(
            Blog::Model::Schema::Post->new(
                author => Blog::Model::Schema::Author->new( name => $author ),
                title  => $title,
                url    => $url,
                body   => $body
            )
        );
    }

    method edit_post ( $url ) {
        my $post = $blog->find_post( fun ( $post ) { $post->url eq $url } );
        die "Could not find post for $url" unless $post;

        $post->author( Blog::Model::Schema::Author->new( name => $editor->prompt('Author : ', $post->author->name ) ) );
        $post->title ( $editor->prompt('Title  : ', $post->title  ) );
        $post->url   ( $editor->prompt('URL    : ', $post->url    ) );
        $post->body  ( $editor->invoke( $post->body ) );
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



