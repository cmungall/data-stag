#!/usr/local/bin/perl -w

# POD docs at bottom of file

use strict;
use Data::Stag qw(:all);
use Data::Stag::StagDB;
use Getopt::Long;

my $record_type;
my $unique_key;
my $dir;
my $fmt = '';
my $outfmt;
my $help;
my $top;
my $indexfile;
my $qf;
my @query = ();
my $keys;
my $reset;
GetOptions("record_type|r=s"=>\$record_type,
	   "unique_key|unique|u=s"=>\$unique_key,
	   "parser|format|p=s"=>\$fmt,
	   "handler|writer|w=s"=>\$outfmt,
	   "indexfile|index|i=s"=>\$indexfile,
	   "top=s"=>\$top,
	   "query|q=s@"=>\@query,
	   "qf=s"=>\$qf,
	   "help|h"=>\$help,
	   "keys"=>\$keys,
	   "reset"=>\$reset,
	  );
if ($help) {
    system("perldoc $0");
    exit 0;
}


my $sdb = Data::Stag::StagDB->new;

$sdb->record_type($record_type) if $record_type;
$sdb->unique_key($unique_key) if $unique_key;
$sdb->indexfile($indexfile) if $indexfile;
$sdb->reset() if $reset;

foreach my $file (@ARGV) {
    my $p;
    if ($file eq '-') {
	$fmt ||= 'xml';
	$p = Data::Stag->parser(-format=>$fmt, -fh=>\*STDIN);
	$p->handler($sdb);
	$p->parse(-fh=>\*STDIN);
    }
    else {
	if (!-f $file) {
	    print "the file \"$file\" does not exist\n";
	}
	$p = Data::Stag->parser($file, $fmt);
	$p->handler($sdb);
	$p->parse($file);
    }
}

if ($qf) {
    open(F, $qf) || die "cannot open queryfile: $qf";
    @query = map {chomp;$_} <F>;
    close(F);
}

if ($keys) {
    my $idx = $sdb->index_hash;
    printf "$_\n", $_ foreach (keys %$idx);
}

if (@query) {
    
    my $w;
    if ($outfmt) {
	$w = Data::Stag->getformathandler($outfmt);
    }
    else {
	$w = Data::Stag->makehandler;
    }
    if ($top) {
	$w->start_event($top);
    }
    my $idx = $sdb->index_hash;
    my $n_found = 0;
    foreach my $q (@query) {
	my $nodes = $idx->{$q} || [];
	if (!@$nodes) {
	    print STDERR "Could not find a record indexed by key: \"$q\"\n";
	    next;
	}
	foreach my $node (@$nodes) {
	    $n_found++;
	    if ($w) {
		$node->sax($w);
	    }
	    else {
		print $node->xml;
	    }
	}
    }
    if ($top) {
	$w->end_event($top);
    }
    if (!$n_found && !$top) {
	print STDERR "NONE FOUND!\n";
    }
    else {
	if (!$outfmt) {
	    print $w->stag->xml;
	}
    }
}


=head1 NAME 

stag-db.pl - persistent storage and retrieval for stag data (xml, sxpr, itext)

=head1 SYNOPSIS

  stag-db.pl -r person -u social_security_no -i ./person-idx myrecords.xml
  stag-db.pl -i ./person-idx -q 999-9999-9999 -q 888-8888-8888

=head1 DESCRIPTION

Builds a simple file-based database for persistent storage and
retrieval of nodes from a stag compatible document.

Imagine you have a very large file of data, in a stag compatible
format such as XML. You want to index all the elements of type
B<person>; each person can be uniquely identified by
B<social_security_no>, which is a direct subnode of B<person>

The first thing to do is to build an index file, which will be stored
in your current directory:

  stag-db.pl -r person -u social_security_no -i ./person-idx myrecords.xml

You can then use the index "person-idx" to retrieve B<person> nodes by
their social security number

  stag-db.pl -i ./person-idx -q 999-9999-9999 > some-person.xml

You can export using different stag formats

  stag-db.pl -i ./person-idx -q 999-9999-9999 -w sxpr > some-person.xml

You can retrieve multiple nodes (although these need to be rooted to
make a valid file)

  stag-db.pl -i ./person-idx -q 999-9999-9999 -q 888-8888-8888 -top personset

Or you can use a list of IDs from a file (newline delimited)

  stag-db.pl -i ./person-idx -qf my_ss_nmbrs.txt -top personset

=head1 ARGUMENTS

=head1 SEE ALSO

L<Data::Stag>

For more complex stag to database mapping, see L<DBIx::DBStag> and the
scripts

L<stag-storenode.pl>

L<selectall_xml>

=cut

