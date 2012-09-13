#!perl

use v5.16;

use Blog::Model;
use Blog::Model::Util;


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

