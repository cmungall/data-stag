#!/usr/local/bin/perl -w

# POD docs at end

use strict;

use Data::Stag qw(:all);
use Getopt::Long;


my @cols = ();
my $sep = "\t";
my $parser;
GetOptions(
           "parser|format|p=s" => \$parser,
	   "cols|c=s@"=>\@cols,
	   "help|h"=>sub { system("perldoc $0"); exit },
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
@cols = map {split/\,/,$_} @cols;

my $np = scalar @cols;
my %idx = map {$cols[$_]=>$_} (0..$#cols);
my @vals = map {undef} @cols;
my @level_idx = ();

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
	for (my $j=$i+1;$j<@vals;$j++) {
	    $vals[$j] = undef;
	}
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
exit 0;

__END__

=head1 NAME 

stag-flatten.pl - turns stag data into a flat table

=head1 SYNOPSIS

  stag-flatten.pl MyFile.xml dept/name dept/person/name

=head1 DESCRIPTION

reads in a file in a stag format, and 'flattens' it to a tab-delimited
table format. given this data:

  (company
   (dept
    (name "special-operations")
    (person
     (name "james-bond"))
    (person
     (name "fred"))))

the above command will return a two column table

  special-operations      james-bond
  special-operations      fred

=head1 USAGE

  stag-flatten.pl [-p PARSER] [-c COLS] [-c COLS]... <file> [COL][COL]...

=head1 ARGUMENTS

=over

=item -p|parser FORMAT

FORMAT is one of xml, sxpr or itext

xml assumed as default

=item -c|column COL1,COL2,COL3,..

the name of the columns/elements to write out

(alternatively this argument can be written after the filename is
specified)

=back

=head1 BUGS

still not working quite right...

=head1 SEE ALSO

L<Data::Stag>

=cut

