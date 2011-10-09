#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use mop;

BEGIN {
    # create a meta-class (class to create classes with)
    class 'MetaWithData' => (extends => $::Class) => sub {

        has( my $data ) = [];

        method 'get_data' => sub { $data };
        method 'add_to_data' => sub {
            my $value = shift;
            push @$data => $value;
        }
    };
}

is MetaWithData->class, $::Class, '... got the class we expected';
ok MetaWithData->is_a( $::Object ), '... MetaWithData is an Object';
ok MetaWithData->is_a( $::Class ), '... MetaWithData is a Class';
ok MetaWithData->is_subclass_of( $::Object ), '... MetaWithData is a subclass of Object';
ok MetaWithData->is_subclass_of( $::Class ), '... MetaWithData is a subclass of Class';

BEGIN {

    # create a class (using our meta-class)
    class 'Foo' => (metaclass => MetaWithData) => sub {
        method 'get_meta_data' => sub {
            $::CLASS->get_data
        }
    };

    # create a class (using our meta-class and extra data)
    class 'Bar' => (metaclass => MetaWithData, data => [ 1, 2, 3 ]) => sub {
        method 'get_meta_data' => sub {
            $::CLASS->get_data
        }
    };
}

is Foo->class, MetaWithData, '... got the class we expected';
ok Foo->is_a( $::Object ), '... Foo is an Object';
ok Foo->is_a( $::Class ), '... Foo is a Class';
ok Foo->is_a( MetaWithData ), '... Foo is a MetaWithData';
ok Foo->is_subclass_of( $::Object ), '... Foo is a subclass of Object';

is_deeply Foo->get_data, [], '... called the static method on Foo';

is Bar->class, MetaWithData, '... got the class we expected';
ok Bar->is_a( $::Object ), '... Bar is an Object';
ok Bar->is_a( $::Class ), '... Bar is a Class';
ok Bar->is_a( MetaWithData ), '... Bar is a MetaWithData';
ok Bar->is_subclass_of( $::Object ), '... Bar is a subclass of Object';

is_deeply Bar->get_data, [ 1, 2, 3 ], '... called the static method on Bar';

isnt Foo->get_data, Bar->get_data, '... the two classes share a different class level data';

{
    my $foo = Foo->new;
    ok $foo->is_a( Foo ), '... got an instance of Foo';
    is_deeply $foo->get_meta_data, [], '... got the expected foo metadata';
    is $foo->get_meta_data, Foo->get_data, '... and it matches the metadata for Foo';

    my $foo2 = Foo->new;
    ok $foo2->is_a( Foo ), '... got an instance of Foo';
    is_deeply $foo2->get_meta_data, [], '... got the expected foo metadata';
    is $foo2->get_meta_data, Foo->get_data, '... and it matches the metadata for Foo';
    is $foo2->get_meta_data, $foo->get_meta_data, '... and it is shared across instances';

    Foo->add_to_data( 10 );
    is_deeply Foo->get_data, [ 10 ], '... got the expected (changed) Foo metadata';

    is_deeply $foo->get_meta_data, [ 10 ], '... got the expected (changed) foo metadata';
    is_deeply $foo2->get_meta_data, [ 10 ], '... got the expected (changed) foo metadata';

    is $foo->get_meta_data, Foo->get_data, '... and it matches the metadata for Foo still';
    is $foo2->get_meta_data, Foo->get_data, '... and it matches the metadata for Foo still';
    is $foo2->get_meta_data, $foo->get_meta_data, '... and it is shared across instances still';
}

{
    my $bar = Bar->new;
    ok $bar->is_a( Bar ), '... got an instance of Bar';
    is_deeply $bar->get_meta_data, [ 1, 2, 3 ], '... got the expected bar metadata';
    is $bar->get_meta_data, Bar->get_data, '... and it matches the metadata for Bar';

    my $bar2 = Bar->new;
    ok $bar2->is_a( Bar ), '... got an instance of Bar';
    is_deeply $bar2->get_meta_data, [1, 2, 3], '... got the expected bar metadata';
    is $bar2->get_meta_data, Bar->get_data, '... and it matches the metadata for Bar';
    is $bar2->get_meta_data, $bar->get_meta_data, '... and it is shared across instances';

    Bar->add_to_data( 10 );
    is_deeply Bar->get_data, [ 1, 2, 3, 10 ], '... got the expected (changed) Bar metadata';

    is_deeply $bar->get_meta_data, [ 1, 2, 3, 10 ], '... got the expected (changed) bar metadata';
    is_deeply $bar2->get_meta_data, [ 1, 2, 3, 10 ], '... got the expected (changed) bar metadata';

    is $bar->get_meta_data, Bar->get_data, '... and it matches the metadata for Bar still';
    is $bar2->get_meta_data, Bar->get_data, '... and it matches the metadata for Bar still';
    is $bar2->get_meta_data, $bar->get_meta_data, '... and it is shared across instances still';

    is_deeply Foo->get_data, [ 10 ], '... got the expected (unchanged) Foo metadat';
}


done_testing;