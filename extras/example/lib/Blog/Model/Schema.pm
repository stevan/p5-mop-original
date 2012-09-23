package Blog::Model::Schema;
use v5.16;
use mop;

use List::Util qw[ first ];

role Packable {
    method pack;   # ( ()      => HashRef )
    method unpack; # ( HashRef => $self   )
}

class Author ( roles => [ Packable ] ) {
    has $name;

    method name { $name }

    method pack { return +{ name => $name } }

    method unpack ( $data ) {
        $name = $data->{'name'};
        $self;
    }
}

class Post ( roles => [ Packable ] )  {
    has $title;
    has $author;
    has $url;
    has $body;

    method title  ( $t ) { $title  = $t if $t; $title  }
    method author ( $a ) { $author = $a if $a; $author }
    method url    ( $u ) { $url    = $u if $u; $url    }
    method body   ( $b ) { $body   = $b if $b; $body   }

    method pack {
        return +{
            title  => $title,
            author => $author->pack,
            url    => $url,
            body   => $body
        }
    }

    method unpack ( $data ) {
        $title  = $data->{'title'};
        $author = Author->new->unpack( $data->{'author'} );
        $url    = $data->{'url'};
        $body   = $data->{'body'};
        $self;
    }
}

class Blog ( roles => [ Packable ] )  {
    has @posts;

    method find_post ( $callback ) {
        first { $callback->( $_ ) } @posts
    }

    method add_post ( $post ) {
        push @posts => $post
    }

    method pack {
        return +{ posts => [ map { $_->pack } @posts ] }
    }

    method unpack ( $data ) {
        foreach my $post ( @{ $data->{'posts'} } ) {
            push @posts => Post->new->unpack( $post );
        }
        $self;
    }
}

1;



