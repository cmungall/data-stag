package Data::Stag;

use strict;
use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    'NAME'         => __PACKAGE__,
    'VERSION_FROM' => "Data/Stag",
    'EXE_FILES'    => [
        'scripts/stag-parse.pl',
    ],
    'PREREQ_PM'    => {
        'XML::Parser::PerlSAX'  => 0, 
        'Pod::Usage'         => 0,
    },
    clean => {
        FILES => 'Data-Stag-$(VERSION).tar.gz',
    },
);

