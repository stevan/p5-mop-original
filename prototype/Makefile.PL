use strict;
use warnings;
use inc::Module::Install;

name 'p5-mop';
all_from 'lib/mop.pm';
license 'perl';

requires 'Sub::Name'            => 0;
requires 'Devel::Declare'       => 0;
requires 'B::Hooks::EndOfScope' => 0;
requires 'PadWalker'            => 0;
requires 'Scope::Guard'         => 0;
requires 'Carp'                 => 0;
requires 'Clone'                => 0;
requires 'UUID::Tiny'           => 0;
requires 'MRO::Magic'           => 0;

build_requires 'Test::More' => 0;

tests('t/*.t');

WriteAll();