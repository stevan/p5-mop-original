#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

{
	package Foo;
	use mop;
	class Bar {
		method go {
			return 'package Foo, class Bar';
		}
	}
}


{
	package Foo::Bar;
	sub new {
		bless []=> shift;
	}
	sub go {
		return 'package Foo::Bar';
	}
}

is(
	Foo::Bar->new->go,
	'package Foo, class Bar',
);

is(
	'Foo::Bar'->new->go,
	'package Foo::Bar',
);

