use v5.16;
use mop;

use Try;
use YAML::XS qw[ LoadFile ];

class Blog::Config {
    has $data;
    has $defaults = {
        storage => './blog.json',
        editor  => '/usr/bin/pico'
    };

    BUILD ($params) {
        my $filename = $params->{'config_file'} || 'my_blog.yml';
        (-e $filename)
            || die "Could not find config file named: $filename";
        try {
            $data = LoadFile( $filename );
        } catch {
            die "Failed to parse config file: $filename because: $_";
        }
    }

    method get ( $key ) { $data->{ $key } // $defaults->{ $key } }
}

1;