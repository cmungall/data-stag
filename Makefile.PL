# $id$

use ExtUtils::MakeMaker;
require 5.004;
#use Config;

WriteMakefile(
	      'NAME'         => "Data",
	      'ABSTRACT'     => 'Structured Tags',
	      'AUTHOR'       => 'Chris Mungall <cjm@fruitfly.org>',
	      'dist'  => { COMPRESS    => 'gzip -9f',
			   SUFFIX      => 'gz'},
	      'VERSION_FROM' => "Data/Stag.pm",
	      'PREREQ_PM'    => {
				 'XML::Parser::PerlSAX'  => 0, 
				 'Pod::Usage'         => 0,
				},
	      'EXE_FILES'    => [
				 'scripts/stag-parse.pl',
				],
	      
	      clean => {
			FILES => 'Data-Stag-$(VERSION).tar.gz',
		       },
	     );

