package Blog::Controller::Resource;
use v5.16;

use Blog::Model;
use Blog::Model::Util qw[ encode_model decode_model ];

use parent 'Web::Machine::Resource';

my $BLOG = Blog::Model::Blog->new(
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

sub content_types_provided { [{ 'text/html' => 'to_html' }] }

sub to_html {
    my $JSON = encode_model( $BLOG );
    qq[
<html>
<body>
<pre>
$JSON
</pre>
</body>
</html>
    ]
}

1;