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
my $name;
my $defs;
GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parser,
           "handler|writer|w=s" => \$handler,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
	   "name|n=s"=>\$name,
	   "defs"=>\$defs,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

#my @hdr = ();
#if ($name) {
#    push(@hdr, (name=>$name));
#}

my @files = @ARGV;
foreach my $fn (@files) {

    my $tree = 
      Data::Stag->parse($fn, 
                        $parser);
    my $s = $tree->autoschema;
    if ($defs) {
	my @sdefs = ();
	my %u = ();
	$s->iterate(sub {
			my $stag = shift;
			my $n = $stag->name;
			$n =~ s/[\+\?\*]$//;
			return if $u{$n};
			$u{$n}=1;
			push(@sdefs, ($n=>''));
			return;
		    });
	$s = Data::Stag->unflatten(schemadefs=>[@sdefs]);
    }
    else {
	$s->iterate(sub {
			my $stag = shift;
			my $d = $stag->data;
			if (!ref $d) {
			    $stag->data($d =~ /INT/ ? "i" : "s");
			}
		    });
    }
#    my $top = 
#      Data::Stag->unflatten(schema=>[
#				     @hdr,
#				    ]);
#    $top->set_nesting($s->data);
    if ($toxml) {
        print $s->xml;
    }
    else {
        print $s->generate(-fmt=>$handler);
    }
}

