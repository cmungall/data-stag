# $id$

use ExtUtils::MakeMaker;
require 5.004;
#use Config;

WriteMakefile(
	      'NAME'         => "Data",
	      'DISTNAME'         => "Data-Stag",
	      'ABSTRACT'     => 'Structured Tags',
	      'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
	      'VERSION_FROM' => "Data/Stag.pm",
	      'PREREQ_PM'    => {
				 'XML::Handler::XMLWriter' => 0,
				 'XML::Parser::PerlSAX'  => 0, 
				 'Pod::Usage'         => 0,
				},
	      'EXE_FILES'    => [
                                 qw(
                                    scripts/stag-splitter.pl
                                    scripts/stag-parse.pl
                                    scripts/stag-view.pl
                                    scripts/stag-itext2xml.pl
                                    scripts/stag-xmlsplit.pl
                                    scripts/stag-itext2simple.pl
                                    scripts/stag-autoschema.pl
                                    scripts/stag-findsubtree.pl
                                    scripts/stag-itext2sxpr.pl
                                    scripts/stag-mogrify.pl
                                    scripts/stag-xml2itext.pl
                                    scripts/stag-handle.pl
                                    scripts/stag-flatten.pl
                                   )
				],
	      'dist'         => { 
				 'SUFFIX'       => ".gz",
				 'DIST_DEFAULT' => 'all tardist',
				 'COMPRESS'     => "gzip -9f" 
				},
	      clean => {
			FILES => 'Data-Stag-$(VERSION).tar.gz',
		       },
	     );

