# $Id: SxprParser.pm,v 1.16 2004/07/21 18:36:49 cmungall Exp $
#
# Copyright (C) 2002 Chris Mungall <cjm@fruitfly.org>
#
# See also - http://stag.sourceforge.net
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

package Data::Stag::SxprParser;

=head1 NAME

  SxprParser.pm     - parses Stag S-expression format

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION


=head1 AUTHOR

=cut

# TODO - rewrite using Text::Balanced

use Exporter;
use Carp;
use FileHandle;
use strict;
use Data::Stag qw(:all);
use base qw(Data::Stag::BaseGenerator Exporter);

use vars qw($VERSION);
$VERSION="0.07";

sub fmtstr {
    return 'sxpr';
}

sub parse_fh {
    my $self = shift;
    my $fh = shift;

#    my $sxpr = join("", <$fh>);
#    $self->sxpr2tree($sxpr);

    my $parsing_has_started;

    my $OPEN = '^\s*\(([\w\-\*\?\+\@\.]+)\s*';
    my $CLOSE = '(.*)(.)\){1}';
    my $txt;
    my $in;
    while (<$fh>) {
#        chomp;
        s/\;\;.*//;
        while ($_) {

	    # we allow an optional leading quote;
	    # this is a lisp list constructor
	    if (/^\s*\'/ && !$parsing_has_started) {
		s/^\s*\'//;
	    }
	    $parsing_has_started = 1;
#            print ";;; $_\n";
            if (/^\)/) {
                $_ = " $_";
            }
            if (/$OPEN(.*)/) {
#                print "S:$1\n";
                $self->start_event($1);
                s/$OPEN//;
                $txt = undef;
                $in = 1;
            }
            elsif (/$CLOSE/ && $2 ne "\\") {
                my $line = "$1$2";
                my $n_close = 1;
                while ($line =~ /$CLOSE/ && $2 ne "\\") {
                    $line = "$1$2";
                }
                my $slice_dist = length($line) +1;
#                print "+++ $line\n";
                while ($line =~ /\)\s*$/) {
                    $n_close++;
                    $line =~ s/\)\s*$//;
                }
                if ($in) {
                    $txt = '' unless defined $txt;
		    if ($line eq ' ') {
			$line = '';
		    }
                    $txt .= $line;
                    if (defined($txt)) {
                        $txt =~ s/^\s*\"//;
                        $txt =~ s/\"\s*$//;
                        $self->evbody($txt);
#                        print "T:$txt\n";
                    }
                }
                else {
                    # after a ')'...
                    $line =~ s/\s*//g;
                    if ($line) {
                        $self->throw("TEXT BETWEEN CLOSING BRACKETS: $line\n");
                    }
                }
                $txt = undef;
                while ($n_close) {
                    $self->end_event();
                    $n_close--;
                }
#                print "E:\n";
#                s/$CLOSE//;
                $_ = substr($_, $slice_dist);
                $in = 0;
            }
            else {
                $txt = '' unless defined $txt;
                $txt .= $_;
                $_ = '';
            }
        }
    }

    return;
}


1;
