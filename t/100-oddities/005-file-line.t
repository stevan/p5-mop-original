#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use mop;

class FileLine (extends => $::Class) {
    has $file;
    has $line;
    has $package;

    method file    { $file    }
    method line    { $line    }
    method package { $package }
}

my $line = __LINE__;
{
    package Foo;
    use mop;
    class Foo (
        metaclass => ::FileLine,
        file      => __FILE__,
        line      => __LINE__,
        package   => __PACKAGE__,
    ) {
        has $file    = __FILE__;
        has $line    = __LINE__;
        has $package = __PACKAGE__;

        method file    { $file    }
        method line    { $line    }
        method package { $package }

        method FILE    { __FILE__    }
        method LINE    { __LINE__    }
        method PACKAGE { __PACKAGE__ }
    }
}

{
    is(Foo::Foo->file,      __FILE__);
    is(Foo::Foo->new->file, __FILE__);
    is(Foo::Foo->new->FILE, __FILE__);

    is(Foo::Foo->line,      $line + 7);
    is(Foo::Foo->new->line, $line + 11);
    is(Foo::Foo->new->LINE, $line + 19);

    is(Foo::Foo->package,      'Foo');
    is(Foo::Foo->new->package, 'Foo');
    is(Foo::Foo->new->PACKAGE, 'Foo');
}

done_testing;
