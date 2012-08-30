use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN { require 5.014 }

use Devel::CallParser ();

{
    open my $fh, '>', 'callparser1.h'
        or die "Couldn't open callparser1.h for writing: $!";
    $fh->print(Devel::CallParser::callparser1_h);
    $fh->close
        or die "Couldn't close callparser1.h: $!";
}

WriteMakefile(
    NAME         => 'mop',
    VERSION_FROM => 'lib/mop.pm',
    PREREQ_PM    => {
        'Package::Anon' => 0.01,
        'Sub::Name'     => 0,
        'PadWalker'     => 0,
        'Scope::Guard'  => 0,
        'Carp'          => 0,
        'UUID::Tiny'    => 0,
        'Scalar::Util'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'     => 0,
        'Test::Fatal'    => 0,
        'Test::Requires' => 0,
    },
    test           => {
        TESTS => 't/*.t t/*/*.t t/*/*/*.t',
    },
    clean => {
        FILES => 'callparser1.h parser$(OBJ_EXT)',
    },
    OBJECT => 'parser$(OBJ_EXT)',
);
