# $Id: XMLParser.pm,v 1.6 2003/05/27 06:49:31 cmungall Exp $
#
# Copyright (C) 2002 Chris Mungall <cjm@fruitfly.org>
#
# See also - http://stag.sourceforge.net
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

package Data::Stag::XMLParser;

=head1 NAME

  XMLParser.pm     - simple wrapper for 

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

use vars qw($VERSION);
$VERSION="0.03";

sub parse_fh {
    my $self = shift;
    my $fh = shift;
    my $parser = XML::Parser::PerlSAX->new();
    my $source = {ByteStream => $fh};
    my %parser_args = (Source => $source,
                       Handler => $self->handler);
    $parser->parse(%parser_args);
}


1;
