#!/usr/bin/perl

use strict;
use warnings;

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
    my $post = Blog::Model::Schema::Post->new;
    ok $post->isa( Blog::Model::Schema::Post ), '... isa Blog::Model::Schema::Post';
    ok $post->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';
}

{
    my $blog = Blog::Model::Schema::Blog->new;
    ok $blog->isa( Blog::Model::Schema::Blog ), '... isa Blog::Model::Schema::Blog';
    ok $blog->does( Blog::Model::Schema::Packable ), '... does Blog::Model::Schema::Packable';
}

done_testing;