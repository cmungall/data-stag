package Data::Stag::ITextWriter;

=head1 NAME

  Data::Stag::ITextWriter

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Base);

use vars qw($VERSION);
$VERSION="0.01";

sub init {
    my $self = shift;
    my ($fn) = @_;
    $self->stack([]);
    $self->fh(\*STDOUT);
    if ($fn) {
	$self->fh(FileHandle->new(">$fn") || die($fn));
    }
    return;
}

sub fh {
    my $self = shift;
    $self->{_fh} = shift if @_;
    return $self->{_fh};
}


sub stack {
    my $self = shift;
    $self->{_stack} = shift if @_;
    return $self->{_stack};
}

sub indent_txt {
    my $self = shift;
    my $stack = $self->stack;
    return "  " x scalar(@$stack);
}

sub o {
    my $self = shift;
    my @o = @_;
    my $fh = $self->fh;
    print $fh $self->indent_txt() . "@o"
}

sub start_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->stack;
    my $fh = $self->fh;
    print $fh "\n" . $self->indent_txt() . "$ev: ";
    push(@$stack, $ev);
}
sub end_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->stack;
    my $top = pop @$stack;
    use Carp;
    $top eq $ev or confess("$top ne $ev");
    return $ev;
}
sub evbody {
    my $self = shift;
    my $body = shift;
    my $fh = $self->fh;
    my $str = itextesc($body);
    print $fh $str;
    return;
}

sub itextesc {
    my $w = shift || "";
    $w =~ s/:/\\:/g;
    return $w;
}

1;
