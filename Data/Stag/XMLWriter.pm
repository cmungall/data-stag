package Data::Stag::XMLWriter;

=head1 NAME

  Data::Stag::XMLWriter

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Base);

use vars qw($VERSION);
$VERSION="0.01";

use XML::Handler::XMLWriter;


sub writer {
    my $self = shift;
    $self->{_writer} = shift if @_;
    return $self->{_writer};
}

sub init {
    my $self = shift;
    my ($fn) = @_;
    my %wh =
      (
     Data_mode=>1,
       Data_indent=>2,
       Newlines=>1,
       );
    
    if ($fn) {
	$wh{OUTPUT} =
	  FileHandle->new(">$fn") || die($fn);
    }
    my $writer = XML::Handler::XMLWriter->new(
					      %wh
					      );
    $self->writer($writer);
    $writer->start_document;
    return;
}

sub start_event { shift->writer->start_element({Name => shift})};
sub end_event { shift->writer->end_element({Name => shift})};
sub evbody { my $self=shift;my $b=shift;$self->writer->characters({Data => $b}) if $b};

1;
