use v5.16;
use mop;

use YAML::XS qw[ LoadFile ];

class Blog::Config {
    has $data;
    has $defaults = {
        storage => './blog.json',
        editor  => '/usr/bin/pico'
    };

    BUILD ($params) {
        $data = LoadFile( $params->{'config_file'} || 'my_blog.yml' );
    }

    method get ( $key ) { $data->{ $key } // $defaults->{ $key } }
}

1;