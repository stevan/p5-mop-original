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

# generate the copy of the tests for mop::mini
use File::Find;
use File::Path;

File::Path::rmtree('t/500-mini');
mkdir 't/500-mini';

# these tests will never work with the mini-mop
my @skip = (
    qr{/000-bootstrap\.t$},
    qr{/010-core/102-clone\.t$},
    qr{/020-metaclass(?=/|$)},
    qr{/030-extensions(?=/|$)},
    qr{/050-roles/002-basic\.t$},
    qr{/050-roles/anonymous_roles\.t$},
    qr{/050-roles/create_role\.t$},
    qr{/050-roles/overriding\.t$},
    qr{/100-oddities/005-file-line\.t$},
    qr{/200-declare/010-methods\.t$},
    qr{/200-declare/020-has\.t$},
    qr{/200-declare/021-has-w-metadata\.t$},
    qr{/200-declare/022-has-w-block\.t$},
    qr{/200-declare/023-has-w-object\.t$},
    qr{/200-declare/030-BUILD\.t$},
    qr{/ext(?=/|$)},
    qr{/300-ext(?=/|$)},
    qr{/400-yapc-eu-examples/001-basic\.t$},
    qr{/400-yapc-eu-examples/101-guarded-attributes\.t$},
    qr{/400-yapc-eu-examples/lib/GuardedAttribute\.pm$},
);

find(
    {
        wanted => sub {
            return if $File::Find::dir =~ /500-mini/;

            return if grep { $File::Find::name =~ $_ } @skip;

            if (-d $File::Find::name) {
                my $dir = $File::Find::name;
                $dir =~ s{^t(?=/|$)}{t/500-mini};
                if (!-d $dir) {
                    mkdir $dir or die "Couldn't mkdir $dir: $!";
                }
            }
            else {
                my $contents = do {
                    local $/;
                    open my $fh, '<', $File::Find::name
                        or die "Couldn't open $File::Find::name: $!";
                    <$fh>;
                };
                if (/\.t$/) {
                    $contents =~ s[
                        (\#\!.*\n)
                    ][$1BEGIN { \$ENV{PERL_MOP_MINI} = 1 }\n]x;
                }

                my $file = $File::Find::name;
                $file =~ s{^t(?=/|$)}{t/500-mini};
                open my $fh, '>', $file or die "Couldn't open $file: $!";
                $fh->print($contents);
            }
        },
        no_chdir => 1,
    },
    't'
);
