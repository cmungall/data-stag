#!/usr/local/bin/perl -w

use strict;

use Data::Stag qw(:all);
use Getopt::Long;
use Data::Dumper;
use FileHandle;
use Tk;
use Tk::Tree;
use Tk::Label;

my $e = "";
my @prints = ();
my $sep = "\t";
my $parser;
GetOptions("element|e=s"=>\$e,
           "parser|format|p=s" => \$parser,
	   "prints|p=s@"=>\@prints,
	  );

my $fn = shift @ARGV;
my $fh;
if ($fn eq '-') {
    $fh = \*STDIN;
}
else {
    $fh = FileHandle->new($fn) || die $fn;
}
my $stag = Data::Stag->parse(-file=>$fn, -format=>$parser);
my @list = $stag->dlist;
#print join("\n", @list), "\n";

# Create a new main window.
#
my $top = new MainWindow( -title  => "Tree" );

# stolen from DBIx::Tree
my $tree = $top->Scrolled( 'Tree',
                           -separator       => '/',
                           -exportselection => 1,
                           -scrollbars      => 'oe',
                           -height => 40,
                           -width  => -1);
# Pack the tree.
#
$tree->pack( -expand => 'yes',
             -fill   => 'both',
             -padx   => 10,
             -pady   => 10,
             -side   => 'top' );

# When we ran $dbtree->tree earlier, the @list array was populated.
# It doesn't have a top element, so we need to pre-pend one to the 
# list ('/' below).
#
unshift(@list, '/');
foreach ( @list ) {

    my $text = (split( /[^\\]\//, $_ ))[-1]; 

    # If we're on /, let's make its label blank.
    #
    if ($_ eq '/') {
        $text = "";
    }
    $text =~ s[\\\/][\/]g;
    s[\\\/][\\]g;

    # Add the item (in $_) with $text as the label.
    #
    
    print "ADD $_ $text\n";
    $text =~ s/\[\d+\]$//;
    $tree->add( $_, -text => $text );
    
}

$tree->autosetmode();
MainLoop;
