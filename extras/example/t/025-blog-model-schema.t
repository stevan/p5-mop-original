#!/usr/bin/perl

use strict;
use warnings;

use Fun;
use Test::More;
use Test::Fatal;

use lib '../../blib/lib/', '../../blib/arch/';

BEGIN {
    use_ok('Blog');
}

{
    my $author = Blog::Model::Schema::Author->new( name => 'Stevan Little' );
    ok $author->isa( Blog::Model::Schema::Author ), '... isa Blog::Model::Schema::Author';
    ok $author->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';

    is $author->name, 'Stevan Little', '... got the name we expected';

    is_deeply $author->pack, { name => 'Stevan Little' }, '... got the packed structure we expected';

    {
        my $unpacked = Blog::Model::Schema::Author->new->unpack( { name => 'Jesse Luehrs' } );
        ok $unpacked->isa( Blog::Model::Schema::Author ), '... isa Blog::Model::Schema::Author';
        ok $unpacked->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';

        is $unpacked->name, 'Jesse Luehrs', '... got the name we expected';
    }
}

{
    my $post = Blog::Model::Schema::Post->new(
        title  => 'Test Post',
        author => Blog::Model::Schema::Author->new( name => 'Stevan Little' ),
        url    => '/test',
        body   => 'This is a test post.'
    );
    ok $post->isa( Blog::Model::Schema::Post ), '... isa Blog::Model::Schema::Post';
    ok $post->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';

    is $post->title, 'Test Post', '... got the right title';
    ok $post->author->isa(Blog::Model::Schema::Author), '... got the author, which is an instance of Author';
    is $post->author->name, 'Stevan Little', '... got the author';
    is $post->url, '/test', '... got the right url';
    is $post->body, 'This is a test post.', '... got the right body';

    is_deeply
        $post->pack,
        {
            title  => 'Test Post',
            author => { name => 'Stevan Little' },
            url    => '/test',
            body   => 'This is a test post.'
        },
    '... got the right packed value';

    {
        my $unpacked = Blog::Model::Schema::Post->new->unpack({
            title  => 'Test Post',
            author => { name => 'Stevan Little' },
            url    => '/test',
            body   => 'This is a test post.'
        });
        ok $unpacked->isa( Blog::Model::Schema::Post ), '... isa Blog::Model::Schema::Post';
        ok $unpacked->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';

        is $unpacked->title, 'Test Post', '... got the right title';
        ok $unpacked->author->isa(Blog::Model::Schema::Author), '... got the author, which is an instance of Author';
        is $unpacked->author->name, 'Stevan Little', '... got the author';
        is $unpacked->url, '/test', '... got the right url';
        is $unpacked->body, 'This is a test post.', '... got the right body';
    }
}

{
    my $blog = Blog::Model::Schema::Blog->new(
        posts => [
            Blog::Model::Schema::Post->new(
                title  => 'Test Post',
                author => Blog::Model::Schema::Author->new( name => 'Stevan Little' ),
                url    => '/test',
                body   => 'This is a test post.'
            )
        ]
    );
    ok $blog->isa( Blog::Model::Schema::Blog ), '... isa Blog::Model::Schema::Blog';
    ok $blog->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';

    my $post = $blog->find_post( fun ( $p ) { $p->title eq 'Test Post' } );
    ok $post->isa( Blog::Model::Schema::Post ), '... isa Blog::Model::Schema::Post';
    is $post->title, 'Test Post', '... got the right title';
    ok $post->author->isa(Blog::Model::Schema::Author), '... got the author, which is an instance of Author';
    is $post->author->name, 'Stevan Little', '... got the author';
    is $post->url, '/test', '... got the right url';
    is $post->body, 'This is a test post.', '... got the right body';

    is_deeply
        $blog->pack,
        {
            posts => [
                {
                    title  => 'Test Post',
                    author => { name => 'Stevan Little' },
                    url    => '/test',
                    body   => 'This is a test post.'
                },
            ]
        },
    '... got the right packed value';

    {
        my $unpacked = Blog::Model::Schema::Blog->new->unpack({
            posts => [
                {
                    title  => 'Test Post',
                    author => { name => 'Stevan Little' },
                    url    => '/test',
                    body   => 'This is a test post.'
                },
            ]
        });
        ok $unpacked->isa( Blog::Model::Schema::Blog ), '... isa Blog::Model::Schema::Blog';
        ok $unpacked->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';

        my $unpacked_post = $blog->find_post( fun ( $p ) { $p->title eq 'Test Post' } );
        ok $unpacked_post->isa( Blog::Model::Schema::Post ), '... isa Blog::Model::Schema::Post';
        is $unpacked_post->title, 'Test Post', '... got the right title';
        ok $unpacked_post->author->isa(Blog::Model::Schema::Author), '... got the author, which is an instance of Author';
        is $unpacked_post->author->name, 'Stevan Little', '... got the author';
        is $unpacked_post->url, '/test', '... got the right url';
        is $unpacked_post->body, 'This is a test post.', '... got the right body';
    }
}

done_testing;