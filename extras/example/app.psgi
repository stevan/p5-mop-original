#!perl

use v5.16;

package Blog {

    package Blog::Model {
        use mop;

        role Packable { method pack }

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


        package Blog::Model::Util {
            use Fun;
            use JSON::XS ();

            # NOTE:
            # hack until doy fixes the Closure
            # prototype issue with Fun
            # - SL
            sub JSON { state $JSON = JSON::XS->new->pretty; $JSON; }

            fun encode_model ( $blog ) { JSON->encode( $blog->pack ) }
            fun decode_model ( $json ) { Blog::Model::Blog->new->unpack( JSON->decode( $json ) ) }
        }
    }
}


my $blog = Blog::Model::Blog->new(
    posts => [
        Blog::Model::Post->new(
            title  => 'Test Post',
            url    => '/test_post',
            author => Blog::Model::Author->new( name => 'Stevan Little' ),
            body   => 'Testing 1, 2, 3'
        ),
        Blog::Model::Post->new(
            title  => 'Test Post 2',
            url    => '/test_post_2',
            author => Blog::Model::Author->new( name => 'Stevan Little' ),
            body   => 'Testing 1, 2, 3, 4'
        )
    ]
);

say Blog::Model::Util::encode_model(
    Blog::Model::Util::decode_model(
        Blog::Model::Util::encode_model( $blog )
    )
);


1;

