#!/usr/local/bin/perl -w

=head1 NAME 

stag-autoschema.pl

=head1 SYNOPSIS

  stag-autoschema.pl -parser XMLAutoschema -handler ITextWriter file1.txt file2.txt

  stag-autoschema.pl -parser MyMod::MyParser -handler MyMod::MyWriter file.txt

=head1 DESCRIPTION

script wrapper for the Data::Stag modules

=head1 ARGUMENTS

=cut



use strict;

use Carp;
use Data::Stag qw(:all);
use Getopt::Long;

my $parser = "";
my $handler = "xml";
my $mapf;
my $tosql;
my $toxml;
my $toperl;
my $debug;
my $help;
GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}


my @files = @ARGV;
foreach my $fn (@files) {

    my $tree = 
      Data::Stag->parse($fn, 
                        $parser);
    my $s = $tree->autoschema;
    if ($toxml) {
        print $s->xml;
    }
    else {
        $s->generate(-fmt=>$handler);
    }
}

