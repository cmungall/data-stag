package Data::Stag::XMLWriter;

=head1 NAME

  Data::Stag::XMLWriter

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION

=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Writer);
use Data::Stag::Util qw(rearrange);

use vars qw($VERSION);
$VERSION="0.05";


sub fmtstr {
    return 'xml';
}

sub indent_txt {
    my $self = shift;
    my $stack = $self->stack;
    return "  " x scalar(@$stack);
}

sub this_line {
    my $self = shift;
    $self->{_this_line} = shift if @_;
    return $self->{_this_line};
}

sub o {
    my $self = shift;
    my $o = "@_";
    $self->addtext( $o );
}

sub start_event {
    my $self = shift;
    my $ev = shift;
    if (!defined($ev)) {
	$ev = '';
    }
    my $stack = $self->stack;
    if (!@$stack) {
	$self->o("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
    }
    $self->o("\n". $self->indent_txt . "<$ev>");
    push(@$stack, $ev);
}
sub end_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->stack;
    my $popped = pop(@$stack);
    if ($ev && $popped ne $ev) {
        warn("uh oh; $ev ne $popped");
    }
    if (!$ev) {
	$ev = $popped;
    }
    if ($self->{_nl}) {
	$self->o("\n" . $self->indent_txt)
    }
    $self->o("</$ev>");
    $self->{_nl} = 1;
    if (!@$stack) {
	$self->o("\n");
    }
    return $ev;
}
sub evbody {
    my $self = shift;
    my $body = shift;
    my $str;
    $self->{_nl} = 0;
    $str = xmlesc($body);
    $self->o($str);
    return;
}

our $escapes = { '&' => '&amp;',
		 '<' => '&lt;',
		 '>' => '&gt;',
		 '"' => '&quot;'
	       };

sub xmlesc {
    my $w = shift;
    if (!defined $w) {
	$w = '';
    }
    $w =~ s/([\&\<\>])/$escapes->{$1}/ge;
    $w;
}



1;
