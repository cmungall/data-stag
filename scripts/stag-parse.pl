#!/usr/local/bin/perl -w

# POD docs at end

use strict;

use Carp;
use Data::Stag qw(:all);
use Getopt::Long;

my $parser = "";
my $handler = "";
my $errhandler = "";
my $errf;
my $mapf;
my $tosql;
my $toxml;
my $toperl;
my $debug;
my $help;
my $color;

GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "errhandler=s" => \$errhandler,
           "errf|e=s" => \$errf,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
           "colour|color"=>\$color,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

$errhandler =  Data::Stag->getformathandler($errhandler || 'xml');

my @files = @ARGV;
foreach my $fn (@files) {

    $handler = Data::Stag->getformathandler($handler);
    $handler->fh(\*STDOUT) if $handler->can("fh");
    if ($color) {
	$handler->use_color(1);
    }
    if ($errf) {
	$errhandler->file($errf);
    }
    else {
	$errhandler->fh(\*STDERR);
    }
    my @pargs = (-file=>$fn, -format=>$parser, -handler=>$handler, -errhandler=>$errhandler);
    if ($fn eq '-') {
	if (!$parser) {
	    $parser = 'xml';
	}
	@pargs = (-format=>$parser, -handler=>$handler, 
		  -fh=>\*STDIN, -errhandler=>$errhandler);
    }
    my $tree = 
      Data::Stag->parse(@pargs);
    if ($errf) {
	$errhandler->finish;
    }

    if ($toxml) {
        print $tree->xml;
    }
    if ($toperl) {
        print tree2perldump($tree);
    }
}
$errhandler->finish;
exit 0;

__END__

=head1 NAME 

stag-parse.pl - parses a file and fires events (e.g. sxpr to xml)

=head1 SYNOPSIS

  # convert XML to IText
  stag-parse.pl -p xml -w itext file1.xml file2.xml

  # use a custom parser/generator and a custom writer/generator
  stag-parse.pl -p MyMod::MyParser -w MyMod::MyWriter file.txt

=head1 DESCRIPTION

script wrapper for the Data::Stag modules

feeds in files into a parser object that generates nestarray events,
and feeds the events into a handler/writer class

=head1 ARGUMENTS

=over

=item -p|parser FORMAT

FORMAT is one of xml, sxpr or itext, or the name of a perl module

xml assumed as default

=item -w|writer FORMAT

FORMAT is one of xml, sxpr or itext, or the name of a perl module

=item -e|errf FILE

file to store parse error handler output

=item -errhandler FORMAT/MODULE

FORMAT is one of xml, sxpr or itext, or the name of a perl module

all parse error events go to this module

=item -color

Works only if the output handler is able to provide ASCII-colors
(currently supported for itext and xml)

=back


=head1 SEE ALSO

L<Data::Stag>

This script is a wrapper for the method

  Data::Stag->parse()

=cut

