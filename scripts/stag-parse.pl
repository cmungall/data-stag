#!/usr/local/bin/perl -w

=head1 NAME 

stag-parse.pl

=head1 SYNOPSIS

  stag-parse.pl -parser XMLParse -handler ITextWriter file1.txt file2.txt

  stag-parse.pl -parser MyMod::MyParser -handler MyMod::MyWriter file.txt

=head1 DESCRIPTION

script wrapper for the Data::Stag modules

feeds in files into a parser object that generates nestarray events,
and feeds the events into a handler/writer class

=head1 ARGUMENTS

=cut



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

