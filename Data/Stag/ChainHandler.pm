package Data::Stag::ChainHandler;

=head1 NAME

  Data::Stag::ChainHandler

=head1 SYNOPSIS


=cut

=head1 DESCRIPTION


=head1 PUBLIC METHODS -

=cut

use strict;
use base qw(Data::Stag::Base Data::Stag::Writer);

use vars qw($VERSION);
$VERSION="0.02";

sub init {
    my $self = shift;
    return;
}

sub subhandlers {
    my $self = shift;
    $self->{_subhandlers} = shift if @_;
    return $self->{_subhandlers};
}

sub blocked_event {
    my $self = shift;
    $self->{_blocked_event} = shift if @_;
    return $self->{_blocked_event};
}

sub start_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->elt_stack;
    push(@$stack, $ev);

    my $sh = $self->subhandlers;
    my $b = $self->blocked_event;
    if (grep {$_ eq $b} @$stack) {
        $sh->[0]->start_event($ev);
    }
    else {
        foreach (@$sh) {
            $_->start_event($ev);
        }
    }
}

sub evbody {
    my $self = shift;
    my $ev = shift;
    my @args = @_;

    my $stack = $self->elt_stack;

    my $sh = $self->subhandlers;
    my $b = $self->blocked_event;
    if (grep {$_ eq $b} @$stack) {
        $sh->[0]->evbody($ev, @args);
    }
    else {
        foreach (@$sh) {
            $_->evbody($ev, @args);
        }
    }
}

sub event {
    my $self = shift;
    my $ev = shift;
    my @args = @_;
    my $stack = $self->elt_stack;

    my $sh = $self->subhandlers;
    my $b = $self->blocked_event;

    if (grep {$_ eq $b} @$stack) {
        $sh->[0]->event($ev, @args);
    }
    else {
        foreach (@$sh) {
            $_->event($ev, @args);
        }
    }
}

sub chain_event {
    my $self = shift;
    my $type = shift;
    my $ev = shift;
    my @args = @_;
    my $stack = $self->elt_stack;
    push(@$stack, $ev);

    my $sh = $self->subhandlers;
    my $b = $self->blocked_event;
    if (grep {$_ eq $b} @$stack) {
        $sh->[0]->event($ev, @args);
    }
    else {
        foreach (@$sh) {
            $_->event($ev, @args);
        }
    }
}

sub end_event {
    my $self = shift;
    my $ev = shift;

    my $stack = $self->elt_stack;
    pop @$stack;

    my $sh = $self->subhandlers;
    my $b = $self->blocked_event;

    if ($ev eq $b) {
        my ($h, @rest) = @$sh;
        $h->end_event($ev);
        foreach (@rest) {
            my $tree = $h->tree;
            $_->event(@$tree);
        }
    }
    else {

        if (grep {$_ eq $b} @$stack) {
            $sh->[0]->end_event($ev);
        }
        else {
            foreach (@$sh) {
                $_->end_event($ev);
            }
        }
    }
}

1;
