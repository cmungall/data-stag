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
				 'scripts/stag-parse.pl',
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

