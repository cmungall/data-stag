#!/usr/local/bin/perl -w

use Data::Stag qw(:all);
use Data::Stag::ITextParser;
use Data::Stag::SxprWriter;
my $p = Data::Stag::ITextParser->new;
my $h = Data::Stag::SxprWriter->new;
$p->handler($h);
foreach my $f (@ARGV) {
    $p->parse($f);
}



