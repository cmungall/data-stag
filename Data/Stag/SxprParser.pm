# $Id: SxprParser.pm,v 1.4 2002/12/06 23:57:21 cmungall Exp $
#
# Copyright (C) 2002 Chris Mungall <cjm@fruitfly.org>
#
# See also - http://stag.sourceforge.net
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

package Data::Stag::SxprParser;

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
use Data::Stag qw(:all);
use base qw(Data::Stag::BaseGenerator Exporter);

use vars qw($VERSION);
$VERSION="0.01";

sub parse_fh {
    my $self = shift;
    my $fh = shift;

#    my $sxpr = join("", <$fh>);
#    $self->sxpr2tree($sxpr);

    my $parsing_has_started;

    my $OPEN = '^\s*\((\w+)\s*';
    my $CLOSE = '(.*)(.)\){1}';
    my $txt;
    my $in;
    while (<$fh>) {
        chomp;
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

sub sxpr2tree {
    my $self = shift;
    my $sxpr = shift;

    my $indent = shift || 0;
    my $i=0;
    my @args = ();
    while ($i < length($sxpr)) {
        my $c = substr($sxpr, $i, 1);
        print STDERR "c;$c i=$i\n";
        $i++;
        if ($c eq ')') {
            my $funcnode = shift @args;
            print STDERR "f = $funcnode->[1]\n";
#            map {print tree2xml($_)} @args;
#            return [$funcnode->[1] =>[@args]], $i;
        }
        if ($c =~ /\s/) {
            next;
        }
        if ($c eq '(') {
            my ($tree, $extra) = sxpr2tree(substr($sxpr, $i), $indent+1);
            push(@args, $tree);
            $i += $extra;
            printf STDERR "tail: %s\n", substr($sxpr, $i);
        }
        else {
            # look ahead
            my $v = "$c";
            my $p=0;
            while ($i+$p < length($sxpr)) {
                my $c = substr($sxpr, $i+$p, 1);
                if ($c =~ /\s/) {
                    last;
                }
                if ($c eq '(') {
                    last;
                }
                if ($c eq ')') {
                    last;
                }
                $p++;
                $v.= $c;
            }
            $i+=$p;
            push(@args, [arg=>$v]);
        }
    }
#    map {print tree2xml($_)} @args;
    map {bless $_,"Node";$_} @args;
    if (wantarray) {
        return @args;
    }
    

    return;
}

1;
