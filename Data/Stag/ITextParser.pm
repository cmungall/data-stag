# $Id: ITextParser.pm,v 1.1 2002/12/03 19:18:02 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.fruitfly.org/annot/go
#
# You may distribute this module under the same terms as perl itself

package Data::Stag::ITextParser;

=head1 NAME

  ITextParser.pm     - simple wrapper for 

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION


=head1 AUTHOR

=cut

use Exporter;
use Carp;
use FileHandle;
use strict;
use XML::Parser::PerlSAX;
use base qw(Data::Stag::BaseGenerator Exporter);

sub parse_file {
    my $self = shift;
    my $file = shift;
    my $fh = FileHandle->new($file) || $self->throw("cannot open $file");
    my @stack = ();
    my $txt;

    while(<$fh>) {
        chomp;
        s/\\\#/MAGIC_WORD_HASH/g;
        s/\#.*//;
        s/MAGIC_WORD_HASH/\#/g;
        next unless $_;

        # remove trailing ws
        s/\s*$//;

	my $eofre = '\<\<(\S+)' . "\$";
	if (/$eofre/) {
	    my $eof = $1;
	    s/$eofre//;
	    my $sofar = $_;
	    while (<$fh>) {
		last if /^$eof/;
		$sofar .= $_;
	    }
	    $_ = $sofar;
	}

        # get indent level
        /(\s*)(.*)/s;

        my ($indent_txt, $elt) = ($1, $2);
        my $indent = length($indent_txt);
        if ($elt =~ /^(\w+):\s*(.*)$/s) {
            $elt = $1;
            my $nu_txt = $2;

            $self->pop_to_level($indent, $txt, \@stack);
            $txt = undef;
            if ($nu_txt) {
                $txt = $nu_txt;
            }
            $self->start_event($elt);
            push(@stack, [$indent, $elt]);
        }
        else {
            # body
            $txt .= $elt if $elt;
        }
    }
    $fh->close;
    $self->pop_to_level(0, $txt, \@stack);
    return;
}

sub pop_to_level {
    my $self = shift;
    my $indent = shift;
    my $txt = shift;
    my $stack = shift;

    # if buffered pcdata, export it
    if (defined $txt) {
        $self->evbody($txt);
    }
    while (scalar(@$stack) &&
           $stack->[-1]->[0] >= $indent) {
        $self->end_event($stack->[-1]->[1]);
        pop(@$stack);
    }
    return;
}

1;
