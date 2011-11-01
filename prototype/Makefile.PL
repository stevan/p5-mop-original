use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN { require 5.012 }

use Devel::CallParser ();

{
    open my $fh, '>', 'callparser0.h'
        or die "Couldn't open callparser0.h for writing: $!";
    $fh->print(Devel::CallParser::callparser0_h);
    $fh->close
        or die "Couldn't close callparser0.h: $!";
}

WriteMakefile(
    NAME         => 'mop',
    VERSION_FROM => 'lib/mop.pm',
    PREREQ_PM    => {
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
    clean => {
        FILES => 'callparser0.h',
    },
    # XXX: not sure if this is correct
    OBJECT => join(' ', Devel::CallParser::callparser_linkable),
);
