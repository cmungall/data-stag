#!/usr/local/bin/perl -w

use Data::Stag qw(:all);
use Data::Stag::ITextParser;
use Data::Stag::Simple;
use Data::Stag::Base;
my $p = Data::Stag::ITextParser->new;
my $h = Data::Stag::Simple->new;
#my $h = Data::Stag::XMLWriter->new;
$p->handler($h);
foreach my $f (@ARGV) {
    $p->parse($f);
}

