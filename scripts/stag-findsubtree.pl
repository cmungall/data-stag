#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;

my $e = shift @ARGV;
my $tree = xml2tree(@ARGV);
my @subtrees = findSubTree($tree, $e);
foreach my $subtree (@subtrees) {
    print tree2xml($subtree);
}


