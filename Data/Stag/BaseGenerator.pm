# $Id: BaseGenerator.pm,v 1.6 2003/03/29 23:33:58 cmungall Exp $
#
# Copyright (C) 2002 Chris Mungall <cjm@fruitfly.org>
#
# See also - http://stag.sourceforge.net
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

package Data::Stag::BaseGenerator;

=head1 NAME

  Data::Stag::BaseGenerator     - base class for parsers

=head1 SYNOPSIS

=cut

=head1 DESCRIPTION

=head1 AUTHOR

=cut

use Exporter;
@ISA = qw(Exporter);

use Carp;
use FileHandle;
use Data::Stag::Util qw(rearrange);
use Data::Stag::null;
use strict qw(subs vars refs);

# Exceptions

sub throw {
    my $self = shift;
    confess("@_");
}

sub warn {
    my $self = shift;
    warn("@_");
}

sub messages {
    my $self = shift;
    $self->{_messages} = shift if @_;
    $self->{_messages} = [] unless $self->{_messages};
    return $self->{_messages};
}


sub last_evcall_type {
    my $self = shift;
    $self->{_last_evcall_type} = shift if @_;
    return $self->{_last_evcall_type};
}


sub stack {
    my $self = shift;
    $self->{_stack} = shift if @_;
    $self->{_stack} = [] unless $self->{_stack};
    return $self->{_stack};
}

sub stack_top {
    my $self = shift;
    $self->stack->[-1];
}

sub push_stack {
    my $self = shift;
    push(@{$self->stack}, @_);
}

sub pop_stack {
    my $self = shift;
    pop(@{$self->stack});
}

sub pop_stack_to_depth {
    my $self = shift;
    my $depth = shift;
    while ($depth < $self->stack_depth) {
        $self->end_event;
    }
}

sub stack_depth {
    my $self = shift;
    scalar(@{$self->stack});
}

*error_list = \&messages;

sub message {
    my $self = shift;
    my $msg = shift;
    unless (ref($msg)) {
        $msg =
          {msg=>$msg,
           line=>$self->line,
           line_no=>$self->line_no,
           file=>$self->file};
    }
    push(@{$self->messages},
         $msg);
}


# Constructor


=head2 new

  Usage   - my $parser = GO::Parser->new()
  Usage   - my $parser = GO::Parser->new({})
  Returns - GO::Parser
  Args    - GO::Handler, [initialization hashref]

creates a new parser

=cut

sub new {
    my ($class, $init_h) = @_;
    my $self = {};
    $self->{handler} = Data::Stag::null->new;
    if ($init_h) {
	map {$self->{$_} = $init_h->{$_}} keys %$init_h;
    }
    bless $self, $class;
    $self->init if $self->can("init");
    $self;
}

sub load_module {

    my $self = shift;
    my $classname = shift;
    my $mod = $classname;
    $mod =~ s/::/\//g;

    if ($main::{"_<$mod.pm"}) {
    }
    else {
        require "$mod.pm";
    }
}

sub handler {
    my $self = shift;
    if (@_) {
        my $h = shift;
        if ($h && !ref($h)) {
            my $base = "Data::Stag:";
            $h =~ s/^xml$/$base:XMLWriter/;
            $h =~ s/^perl$/$base:PerlWriter/;
            $h =~ s/^sxpr$/$base:SxprWriter/;
            $h =~ s/^itext$/$base:ITextWriter/;
            $h =~ s/^graph$/$base:GraphWriter/;
            $self->load_module($h);
            $h = $h->new;
        }
        $self->{handler} = $h;
    }
#    return $self->{handler} || Data::Stag::null->new();
    return $self->{handler};
}

sub line_no {
    my $self = shift;
    $self->{_line_no} = shift if @_;
    return $self->{_line_no};
}

sub line {
    my $self = shift;
    $self->{_line} = shift if @_;
    return $self->{_line};
}

sub file {
    my $self = shift;
    $self->{_file} = shift if @_;
    return $self->{_file};
}



=head2 parse

  Usage   - $parser->parse($file1, $file2);
  Returns - n/a
  Args    - filename list

delegates results to handler

=cut

sub parse {
    my $self = shift;
    my ($file, $str, $fh) = 
      rearrange([qw(file str fh)], @_);
    if ($str) {
        $self->load_module("IO::String");
        $fh = IO::String->new($str) || confess($str);
    }
    elsif ($file) {
        if ($file eq '-') {
            $fh = \*STDIN;
        }
        else {
            $self->load_module("FileHandle");
            $fh = FileHandle->new($file) || confess($file);
        }
    }
    else {
    }
    if (!$fh) {
        confess("no filehandle");
    }
    $self->parse_fh($fh);
    # problem with IO::String closing in perl5.6.1
    $fh->close unless $str;
    return;
}

sub start_event {
    my $self = shift;
    $self->push_stack($_[0]);
    my $lc = $self->last_evcall_type;
    if ($lc && $lc eq 'evbody') {
        confess("attempting to start event:$_[0] illegally (in terminal node after body)");
    }
    $self->last_evcall_type('start_event');
    $self->handler->start_event(@_);
    $self->check_handler_messages;
}
sub end_event { 
    my $self = shift; 
    my $ev = shift || $self->stack->[-1];
    $self->handler->end_event($ev);

    my $out = $self->pop_stack();
    if ($ev ne $out) {
        confess("MISMATCH: $ev ne $out");
    }
    $self->last_evcall_type('end_event');
    $self->check_handler_messages;
}
sub event {
    my $self = shift;
    my $lc = $self->last_evcall_type;
    if ($lc && $lc eq 'evbody') {
        confess("attempting to start event:$_[0] illegally (in terminal node after body)");
    }

    $self->handler->event(@_);
    $self->last_evcall_type('end_event');
    $self->check_handler_messages;
}
sub evbody {
    my $self = shift;
    my $lc = $self->last_evcall_type;
    if ($lc && $lc eq 'evbody') {
        confess("attempting to event_body illegally (body already defined)");
    }

    $self->handler->evbody(@_);
    $self->last_evcall_type('evbody');

    $self->check_handler_messages;
}

# the handlers may throw errors / complain about stuff;
# catch their messages here, and add them to the parser
# messages
sub check_handler_messages {
    my $self = shift;
    my $msgs = $self->handler->messages ||[];
    if (@$msgs) {
        map {
            $self->message(ref($_) ? $_ : {msg=>$_});
        } @$msgs;
        $self->handler->messages([]);
    }
    return;
}


1;
