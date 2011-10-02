#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

=pod

This test shows how you can import functions
into your package, and then use them in your
class this removes the need to import anything
into your class namespace.

  package DB::FlatFile;
  use strict;
  use warnings;
  use Path::Class qw[ file dir ]

  class DataFile {
      has $path;
      has $file;
      method BUILD {
          $file = file( $path );
      }
  }

=cut

BEGIN {

    package My::DB::FlatFile;
    use strict;
    use warnings;
    use mop;
    my ($self, $class);

    use Path::Class qw[ file ];

    class 'DataFile' => sub {
        has( my $path );
        has( my $file );
        has( my $data );

        method 'data' => sub { $data };

        method 'BUILD' => sub {
            $file = file( $path );
            $data = [ $file->slurp( chomp => 1 ) ];
        };
    };

}

my $data_file = My::DB::FlatFile::DataFile->new( path => __FILE__ );
ok( $data_file->is_a( My::DB::FlatFile::DataFile ), '... the object is from class My::DB::FlatFile::DataFile' );
ok( $data_file->is_a( $::Object ), '... the object is derived from class Object' );
is( $data_file->data->[0], '#!/usr/bin/perl', '... got the first line of the data we expected' );

done_testing;
