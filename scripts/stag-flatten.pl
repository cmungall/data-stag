#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;

my $e = "";
my @prints = ();
my $sep = "\t";
my $parser;
GetOptions("element|e=s"=>\$e,
           "parser|format|p=s" => \$parser,
	   "prints|p=s@"=>\@prints,
	  );

my $fn = shift @ARGV;
my $fh;
if ($fn eq '-') {
    $fh = \*STDIN;
}
else {
    $fh = FileHandle->new($fn) || die $fn;
}
$e = shift @ARGV unless $e;
push(@prints, @ARGV);
my %catch = (
	     $e => sub {
		 my ($self, $stag) = @_;
		 my @tuple =
		   map {
		       '['.
			 join(' ',
			      $stag->get($_)).
				']';
		   } @prints;
		 print join($sep, @tuple), "\n";
#		 print $stag->xml;
		 return;
	     }
	     );
my $p = Data::Stag->parser(-file=>$fn, -format=>$parser);
my $h = Data::Stag->makehandler(%catch);
$p->handler($h);
$p->parse_fh($fh);

