#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;

my $e = "";
my @prints = ();
my $sep = "\t";
GetOptions("element|e=s"=>\$e,
	   "prints|p=s@"=>\@prints,
	  );

my $fn = shift @ARGV;
$e = shift @ARGV unless $e;
push(@prints, @ARGV);
my $stag = Data::Stag->parse($fn);

my @elts = $stag->get($e);
foreach my $elt (@elts) {
    my @tuple =
      map {$elt->get($_)} @prints;
    print join($sep, @tuple), "\n";
}


