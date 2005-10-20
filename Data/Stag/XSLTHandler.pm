# $Id: XSLTHandler.pm,v 1.3 2005/10/20 18:33:26 cmungall Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

=head1 NAME

  Data::Stag::XSLTHandler     - 

=head1 SYNOPSIS



=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS - 

=cut

# makes objects from parser events

package Data::Stag::XSLTHandler;
use base qw(Data::Stag::Base);

use strict;

sub end_stag {
    my $self = shift;
    my $stag = shift;
    $self->SUPER::end_stag($stag);
    my $results = $stag->xsltstr($self->xslt_file);
    $self->addtext($results);
    return;
}

sub xslt_file {
    my $self = shift;
    $self->{_xslt_file} = shift if @_;
    return $self->{_xslt_file} || die "You must subclass XSLTHandler and provide xslt_file";
}

1;
