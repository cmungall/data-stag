# $Id: XMLParser.pm,v 1.2 2002/12/05 04:33:49 cmungall Exp $
#
#
# see also - http://www.geneontology.org
#          - http://www.fruitfly.org/annot/go
#
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
