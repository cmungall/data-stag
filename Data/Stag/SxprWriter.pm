package Data::Stag::SxprWriter;

=head1 NAME

  Data::Stag::SxprWriter

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION

writes lisp style s-expressions

note: more limited than normal s-expressions; all nodes are treated as
functions with one argument.

all leaf/data elements treated as functions with one argument

all other elements treated as functions with list arguments

=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Base Data::Stag::Writer);

use vars qw($VERSION);
$VERSION="0.02";

sub init {
    my $self = shift;
    $self->init_writer(@_);
    $self->stack([]);
    return;
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

sub this_line {
    my $self = shift;
    $self->{_this_line} = shift if @_;
    return $self->{_this_line};
}

sub o {
    my $self = shift;
    my $o = "@_";
    my $pre = " ";

    if (($self->this_line &&
        length($self->this_line) + length($o) > 
        60) ||
#        $o =~ /^[\(\)]/) {
        $o =~ /^\(/) {
	if ($self->indent_txt) {
	    $pre = "\n" . $self->indent_txt;
	}
	else {
	    $pre = "'";
	}
        $self->this_line($pre.$o);
    }
    else {
        if ($o =~ /^\)/) {
            $pre = "";
        }
        $self->this_line($self->this_line . $pre.$o);
    }
    $self->addtext( $pre.$o );

}

sub start_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->stack;
    $self->o("($ev");
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
    $self->o(")");
    return $ev;
}
sub evbody {
    my $self = shift;
    my $body = shift;
    $self->o(lispesc($body));
    return;
}

sub lispesc {
    my $w = shift;
    $w =~ s/\(/\\\(/g;
    $w =~ s/\)/\\\)/g;
    $w =~ s/\"/\\\"/g;
    return '"'.$w.'"';
}

1;
