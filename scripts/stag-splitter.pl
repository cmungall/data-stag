#!/usr/local/bin/perl -w

use strict;
use Data::Stag qw(:all);
use Data::Stag::XMLParser;
use Getopt::Long;

my $split;
my $name;
my $dir;
my $fmt = '';
my $outfmt = '';
my $help;
GetOptions("split|s=s"=>\$split,
	   "name|n=s"=>\$name,
	   "dir|d=s"=>\$dir,
	   "format=s"=>\$fmt,
	   "outformat=s"=>\$outfmt,
	   "help|h"=>\$help,
	  );
print usage() && exit(0) if $help;
my $h = Splitter->new;
if ($dir) {
    `mkdir $dir` unless -d $dir;
    $h->dir($dir);
}
if (!@ARGV) {
    die "no files passed!";
}
$h->split_on_element($split);
$h->name_by_element($name);
$h->fmt($outfmt || $fmt);
foreach my $file (@ARGV) {
    my $p = Data::Stag->parser($file, $fmt);
    $p->handler($h);
    $split = $split || shift @ARGV;
    $p->parse($file);
#    print stag_xml($h->tree);
}

sub usage {
    return <<EOM
Usage: stag-splitter.pl [-split <ELEMENT-NAME>] [-name <ELEMENT-NAME>] [-dir <DIR>] [-format <INPUT-FORMAT>] [-outformat <OUTPUT-FORMAT>] <FILENAMES>

splits a Stag-compatible file (e.g. XML) into multiple files, one for
each element of type specified by the '-split' switch

the files will be named anonymously, unless the '-name' switch is specified; this will use the value of the specified element as the filename

eg; if we have


  <top>
    <a>
      <b>foo</b>
      <c>yah</c>
      <d>
        <e>xxx</e>
      </d>
    </a>
    <a>
      <b>bar</b>
      <d>
        <e>wibble</e>
      </d>
    </a>
  </top>

if we run

  stag-splitter.pl -split a -name b

it will generate two files, "foo.xml" and "bar.xml"

input format can be 'xml', 'sxpr' or 'itext' - if this is left blank
the format will be guessed from the file suffix

the output format defaults to the same as the input format, but
another can be chosen.

files go in the current directory, but this can be overridden with the
'-dir' switch

EOM
}

package Splitter;
use base qw(Data::Stag::BaseHandler);
use Data::Stag qw(:all);

sub dir {
    my $self = shift;
    $self->{_dir} = shift if @_;
    return $self->{_dir};
}

sub split_on_element {
    my $self = shift;
    $self->{_split_on_element} = shift if @_;
    return $self->{_split_on_element};
}

sub fmt {
    my $self = shift;
    $self->{_fmt} = shift if @_;
    return $self->{_fmt};
}


sub name_by_element {
    my $self = shift;
    $self->{_name_by_element} = shift if @_;
    return $self->{_name_by_element};
}

sub i {
    my $self = shift;
    $self->{_i} = shift if @_;
    return $self->{_i} || 0;
}

sub end_event {
    my $self = shift;
    my $ev = shift;
    if ($ev eq $self->split_on_element) {
	my $topnode = $self->popnode;
	my $name_elt = $self->name_by_element;
	my $name;
	if ($name_elt) {
	    $name = stag_get($topnode, $name_elt);
	}
	if (!$name) {
	    $self->i($self->i()+1);
	    $name = $ev."_".$self->i;
	}
	my $dir = $self->dir || '.';
	my $fmt = $self->fmt;
	$fmt = $fmt || 'xml';
	my $fh = FileHandle->new(">$dir/$name.$fmt") || die;
	if ($fmt eq 'xml') {
	    my $out = stag_xml($topnode);
	    print $fh $out;
	}
	else {
	    stag_generate($topnode, -fh=>$fh, -fmt=>$fmt);
	}
	$fh->close;
	return [];
    }
    else {
	return $self->SUPER::end_event($ev, @_);
    }
}

1;

