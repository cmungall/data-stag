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
GetOptions(
           "help|h"=>\$help,
           "parser|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

# Get args

if ($handler) {
    $handler = 
      'Data::Stag::'.$handler
        unless $handler =~ /\:\:/;
}

#$parser = 
#  'Data::Stag::'.$parser
#  unless $parser =~ /\:\:/;

my $handler_obj;
$handler_obj = create_inst($handler) if $handler;
#my $parser_obj = create_inst($parser);

#print STDERR "$parser_obj\n";
my @files = @ARGV;
#$parser_obj->handler($handler_obj) if $handler_obj;
foreach my $fn (@files) {

#    $parser_obj->parse($fn);
    my $tree = Node();
    $tree->parse($fn, $parser, $handler_obj);

    if ($toxml) {
#        my $tree = $handler_obj->tree || [];
        print tree2xml($tree);
    }
    if ($toperl) {
        print tree2perldump($tree);
    }
}
print "\n";

sub load_module {

    my $classname = shift;
    my $mod = $classname;
    $mod =~ s/::/\//g;

    if ($main::{"_<$mod.pm"}) {
    }
    else {
	eval {
	    require "$mod.pm";
	};
	if ($@) {
	    confess $@;
	}
    }
}

sub create_inst {
    
    my $classname = shift;
    load_module($classname);
    return $classname->new;
}

