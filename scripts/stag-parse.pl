#!/usr/local/bin/perl -w

# POD docs at end

use strict;

use Carp;
use Data::Stag qw(:all);
use Getopt::Long;

my $parser = "";
my $handler = "";
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
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
           "colour|color"=>\$color,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}


my @files = @ARGV;
foreach my $fn (@files) {

    $handler = Data::Stag->getformathandler($handler);
    $handler->fh(\*STDOUT) if $handler->can("fh");
    if ($color) {
	$handler->use_color(1);
    }
    my @pargs = (-file=>$fn, -format=>$parser, -handler=>$handler);
    if ($fn eq '-') {
	if (!$parser) {
	    $parser = 'xml';
	}
	@pargs = (-format=>$parser, -handler=>$handler, -fh=>\*STDIN);
    }
    my $tree = 
      Data::Stag->parse(@pargs);

    if ($toxml) {
        print $tree->xml;
    }
    if ($toperl) {
        print tree2perldump($tree);
    }
}
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

=item -color

Works only if the output handler is able to provide ASCII-colors
(currently supported for itext and xml)

=back


=head1 SEE ALSO

L<Data::Stag>


=cut

