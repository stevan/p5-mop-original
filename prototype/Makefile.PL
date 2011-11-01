use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'mop',
    VERSION_FROM   => 'lib/mop.pm',
    PREREQ_PM      => {
        'Package::Anon' => 0,
        'Sub::Name'     => 0,
        'PadWalker'     => 0,
        'Scope::Guard'  => 0,
        'Carp'          => 0,
        'UUID::Tiny'    => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'    => 0,
    },
    test           => {
        TESTS => 't/*.t t/*/*.t t/*/*/*.t',
    },
);
