#!/usr/local/bin/perl

#my @files = (glob("$ENV{HOME}/stag/scripts/*pl"),glob("$ENV{HOME}/DBIx-DBStag/scripts/*pl"));
my @files = (glob("$ENV{HOME}/DBIx-DBStag/scripts/*pl"),glob("$ENV{HOME}/stag/scripts/*pl"));
print STDERR "@files\n";
foreach my $f (@files) {
    my $n = $f;
    $n =~ s/.*\///;
    $n =~ s/\..*//;
    `mkdir script-docs` unless -d 'script-docs';
    system("pod2html --title $f $f > script-docs/$n.html");
}
