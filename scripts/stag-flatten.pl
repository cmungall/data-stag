#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;

my $e = "";
my @cols = ();
my $sep = "\t";
my $parser;
GetOptions("element|e=s"=>\$e,
           "parser|format|p=s" => \$parser,
	   "cols|c=s@"=>\@cols,
	  );

my $fn = shift @ARGV;
my $fh;
if ($fn eq '-') {
    $fh = \*STDIN;
}
else {
    $fh = FileHandle->new($fn) || die $fn;
}
push(@cols, @ARGV);
my $np = scalar @cols;
my %idx = map {$cols[$_]=>$_} (0..$#cols);
my @vals;

sub writerel {
    print join("\t", map {defined($_) ? $_ : 'NULL'} @vals), 
      "\n";
}

sub setcol {
    my ($col, $val) = @_;
    my $i = $idx{$col};
    die $col unless defined $i;
    my $curval = $vals[$i];
    if (defined $curval) {
	writerel();
    }
    $vals[$i] = $val;
    return;
}

my %catch = ();
foreach my $col (@cols) {
    $catch{$col} =
      sub {
	  my ($self, $stag) = @_;
	  setcol($col, $stag->data);
	  return;
      };
}
my $p = Data::Stag->parser(-file=>$fn, -format=>$parser);
my $h = Data::Stag->makehandler(%catch);
$p->handler($h);
$p->parse_fh($fh);
writerel();
