#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;
use FileHandle;

my $exec;
my $codefile;
my $parser = '';
my $writer = '';
my %trap = ();
GetOptions("codefile|c=s"=>\$codefile,
	   "sub|s=s"=>\$exec,
	   "trap|t=s%"=>\%trap,
           "parser|format|p=s" => \$parser,
	   "writer|w=s"=>\$writer,
	  );

if (!$codefile && !$exec) {
    $codefile = shift @ARGV;
    die unless $codefile;
}
my $fn = shift @ARGV;
my $fh;
if (!$fn || $fn eq '-') {
    $fh = \*STDIN;
    $fn = '';
}
else {
    $fh = FileHandle->new($fn) || die $fn;
}

my $p = Data::Stag->parser(-file=>$fn, -format=>$parser);

my $catch = {};
no strict;
if ($exec) {
    $catch = eval $exec;
    if ($@) {
	die $@;
    }
}
if ($codefile) {
    $catch = do "$codefile";
    if ($@) {
	die $@;
    }
}
if (%trap) {
    use Data::Dumper;
    die Dumper \%trap;
    %$catch = (%$catch, %trap);
}
use strict;
my $meth = $exec ?  $exec : $codefile;
if (!%$catch) {
    die "$meth did not return handler";
}
if (!ref($catch) || ref($catch) ne "HASH") {
    die("$meth must return hashref");
}
my @events = keys %$catch;
my $inner_handler = Data::Stag->makehandler(%$catch);
my $h = Data::Stag->chainhandlers([@events],
				 $inner_handler,
				 $writer);
$p->handler($h);
$p->parse_fh($fh);


__END__

=head1 NAME

  stag-handle.pl

=head1 SYNOPSIS

  stag-handle.pl -w itext -c my-handler.pl myfile.xml > processed.itext

=head1 DESCRIPTION

will take a Stag compatible format (xml, sxpr or itext), turn the data
into an event stream passing it through my-handler.pl

=over ARGUMENTS

=item -help|h

shows this document

=item -writer|w WRITER

writer for final transformed tree; can be xml, sxpr or itext

=item -codefile|c FILE

a file containing a perlhashref containing event handlers - see below

=item -sub|s PERL

a perl hashref containing handlers 

=item -trap|t ELEMENT=SUB

=back



=head1 EXAMPLES

  unix> cat my-handler.pl
  {
    person => sub {
	my ($self, $person) = @_;
	$person->set_fullname($person->get_firstname . ' ' .
			   $person->get_lastname);
    },
    address => sub {
	my ($self, $address) = @_;
	# remove addresses altogether from processed file
	$address->free;
    },
  }


=cut
