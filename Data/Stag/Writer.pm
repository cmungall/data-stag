package Data::Stag::Writer;

=head1 NAME

  Data::Stag::Writer

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION

base mixin class for all writers

=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Base);
use Data::Stag::Util qw(rearrange);

use vars qw($VERSION);
$VERSION="0.03";

sub init_writer {
    my $self = shift;
    my ($fn, $fh) = rearrange([qw(file fh)], @_);
    if ($fn) {
	$fh =
	  FileHandle->new(">$fn") || die($fn);
    }
    $fh = \*STDOUT unless $fh;
    $self->fh($fh);
    return;
}

sub fh {
    my $self = shift;
    $self->{_fh} = shift if @_;
    return $self->{_fh} || \*STDOUT;
}


sub addtext {
    my $self = shift;
    my $msg = shift;
    my $fh = $self->fh;
    print $fh $msg;
}

1;
