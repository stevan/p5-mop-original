package Blog::Model {
    use v5.16;
    use mop;

    role Packable {
        method pack;
        method unpack;
    }

    class Author ( roles => [ Packable ] ) {
        has $name;

        method name { $name }

        method pack { +{ name => $name } }

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

        method title  { $title }
        method author { $author }
        method url    { $url }
        method body   { $body }

        method pack {
            +{
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

        method add_post ( $post ) {
            push @posts => $post
        }

        method pack {
            +{ posts => [ map { $_->pack } @posts ] }
        }

        method unpack ( $data ) {
            foreach my $post ( @{ $data->{'posts'} } ) {
                push @posts => Post->new->unpack( $post );
            }
            $self;
        }
    }

}

1;



