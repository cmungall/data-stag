# $Id: XSLHandler.pm,v 1.1 2004/06/16 03:08:22 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  Data::Stag::XSLHandler     - 

=head1 SYNOPSIS



=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package Data::Stag::XSLHandler;
use base qw(Data::Stag::base);
use XML::LibXML;
use XML::LibXSLT;

use strict;


sub e_obo {
    my $self = shift;
    my $stag = shift;
    
    my $parser = XML::LibXML->new();
    my $source = $parser->parse_string($stag->xml);
    
    my $xslt = XML::LibXSLT->new();
    my $file_name = $self->xslt_file;
    my $styledoc = $parser->parse_file($file_name);
    my $stylesheet = $xslt->parse_stylesheet($styledoc);

    my $results = $stylesheet->transform($source);
    print $stylesheet->output_string($results);

}

sub xslt_file {
    die "You must subclass XSLTHandler and provide xslt_file";
}

1;
