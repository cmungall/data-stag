#!/usr/local/bin/perl -w

=head1 NAME 

stag-grep.pl

=head1 SYNOPSIS

  stag-grep.pl person 'sub {shift->get_name =~ /^A*/}' file1.itext 

  stag-grep.pl -parser xml  -handler sxpr record 'sub{..}' file.xml

=head1 DESCRIPTION

filters an input file

=head1 ARGUMENTS

=cut



use strict;

use Carp;
use Data::Stag qw(:all);
use Getopt::Long;

my $parserf = "";
my $out = "";
my $mapf;
my $tosql;
my $toxml;
my $toperl;
my $debug;
my $help;
my $count;
my $ff;
my @queryl = ();
GetOptions(
           "help|h"=>\$help,
           "parser|format|p=s" => \$parserf,
           "handler|writer|w=s" => \$out,
	   "count|c" => \$count,
           "xml"=>\$toxml,
           "perl"=>\$toperl,
           "debug"=>\$debug,
	   "filterfile|f=s"=>\$ff,
	   "query|q=s@"=>\@queryl,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

my $w = shift;
my $sub;
if ($ff) {
    $sub = do $ff;
}
elsif (@queryl) {

    my $ev = 
      'sub { my $s=shift; '.
	join(' && ',
	     map {
		 if (/(\w+)\s*(==|<=|>=|<|>|eq|ne|lt|gt|=)\s*(.*)/) {
		     "\$s->get('$1') $2 $3"
		 }
		 else {
		     die($_);
		 }
	     } @queryl).
	       '}';
    $sub = eval $ev;
    if ($@) {
	die $@;
    }
}
else {
    $sub = shift;
    $sub = eval $sub;

}
if ($@) {
    print $@;
    exit 1;
}

my $c = 0;
my @files = @ARGV;
foreach my $fn (@files) {

    my $handler = Data::Stag->makehandler($w=>sub {
					      my $self = shift;
					      my $stag = shift;
					      my $ok = $sub->($stag);
					      if ($ok) {
						  $c++;
					      }
					      else {
						  $stag->free;
					      }
					      return;
					    });
    if ($count) {
	$out = 'Data::Stag::null';
    }
    
    my $parser = Data::Stag->parser($fn, $parserf);
    if (!$out) {
	$out = $parser->fmtstr;
    }
    my $ch = Data::Stag->chainhandlers($w, $handler, $out);

    my $tree = 
      Data::Stag->parse($fn, 
			$parser, 
			$ch);
    if ($count) {
	print "$c\n";
    }

#    my @res =
#      $tree->where($w,
#		   $sub);
#    print $_->xml foreach @res;
}

