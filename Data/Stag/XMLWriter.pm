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
use Data::Stag::Util qw(rearrange);

use vars qw($VERSION);
$VERSION="0.02";

use XML::Handler::XMLWriter;


sub writer {
    my $self = shift;
    $self->{_writer} = shift if @_;
    return $self->{_writer};
}

sub init {
    my $self = shift;
    my ($fn, $fh) = rearrange([qw(file fh)], @_);
    my %wh =
      (
       Data_mode=>1,
       Data_indent=>2,
       Newlines=>1,
       );
    
    if ($fn) {
	$fh =
	  FileHandle->new(">$fn") || die($fn);
    }
    if ($fh) {
	$self->{_fh} = $fh;
	$wh{OUTPUT} = $fh;
    }
    my $writer = XML::Handler::XMLWriter->new(
					      %wh
					      );
    $self->writer($writer);
    $writer->start_document;
    return;
}

sub DESTROY {
    my $self = shift;
    $self->writer->end_document;
    if ($self->{_fh}) {
	$self->{_fh}->close;
    }
    return;
}

sub start_event { shift->writer->start_element({Name => shift})};
sub end_event { shift->writer->end_element({Name => shift})};
sub evbody { my $self=shift;my $b=shift;$self->writer->characters({Data => $b}) if $b};

1;
