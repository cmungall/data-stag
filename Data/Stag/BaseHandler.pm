# $Id: BaseHandler.pm,v 1.2 2002/12/06 23:57:21 cmungall Exp $
#
# This  module is maintained by Chris Mungall <cjm@fruitfly.org>

=head1 NAME

  Data::Stag::BaseHandler     - Base class for writing tag stream handlers

=head1 SYNOPSIS

  package MyPersonHandler;
  use base qw(Data::Stag::BaseHandler);

use vars qw($VERSION);
$VERSION="0.01";

  # handler that prints person nodes as they are parsed
  sub e_person {
      my $self = shift;
      my $node = shift;
      printf "Person name:%s address:%s\n",
        $node->sget('name'), $node->sget('address');
      return [];  # delete person node
  }
  
  package MyPersonHandler;
  use base qw(Data::Stag::BaseHandler);

  # handler that modifies tree as it goes
  sub e_measurement {
      my $self = shift;
      my $node = shift;
      if ($node->sget('unit') eq 'inch') {
          $node->set('unit', 'cm');
          $node->set('quantity', $node->get('quantity') * 2.5);
      }
      return;   # returnig null leaves it unchanged
  }
  

=cut

=head1 DESCRIPTION

Default Simple Event Handler, other handlers inherit from this class

See also L<Data::Stag>

This class catches Data::Stag node events  (start, end and body) and allows the
subclassing module to intercept these. Unintercepted events get pushed
into a tree.

This class can take SAX events and turn them into simple
Data::Stag events; mixed content and attributes are currently
ignored. email me if you would like this behaviour changed.

the events recognised are

  start_event(node-name)
  evbody(node-data)
  end_event(node-name)

and also

  event(node-name, node-data|node)

which is just a wrapper for the other events

you can either intercept these methods; or you can define methods


  s_<element_name>
  e_<element_name>

that get called on the start/end of an event; you can dynamically
change the structure of the tree by returning nodes from these methods



=head1 PUBLIC METHODS - 

=cut

package Data::Stag::BaseHandler;

use strict;
use Exporter;
#use XML::Filter::Base;
use vars qw(@ISA @EXPORT_OK);
use base qw(Exporter);
use Carp;
use Data::Stag;


=head2 tree

  Usage   -
  Returns -
  Args    -

=cut

sub tree {
    my $self = shift;
    $self->{_tree} = shift if @_;
    return $self->{_tree} || [];
}


sub messages {
    my $self = shift;
    $self->{_messages} = shift if @_;
    return $self->{_messages};
}

*error_list = \&messages;

sub message {
    my $self = shift;
    push(@{$self->messages},
         shift);
}


sub new {
    my ($class, @args) = @_;
#    my $self = XML::Filter::Base::new(@_);
    my $self = {};
    bless $self, $class;
    $self->{node} = [];
    $self->{elt_stack} = [];
    $self->init(@args) if $self->can("init");
    $self;
}

sub node {
    my $self = shift;
    $self->{node} = shift if @_;
    return $self->{node};
}


sub lookup {
    my $tree = shift;
    my $k = shift;
    my @v = map {$_->[1]} grep {$_->[0] eq $k} @$tree;
    if (wantarray) {
        return @v;
    }
    $v[0];
}

sub init {
    my $self = shift;
    $self->messages([]);
    $self->{node} = [];
}

sub perlify {
    my $word = shift;
    $word =~ s/\-/_/g;
    return $word;
}

# start_event is called at the beginning of any event;
# equivalent to the event fired at the opening of any
# xml <tag> in a SAX parser

# action: checks for method of name s_EVENTNAME()
# calls it if it is present
sub start_event {
    my $self = shift;
    my $ev = shift;
    my $node = $self->{node};
    my $m = perlify("s_$ev");
    if ($self->can($m)) {
        $self->$m;
    }
    else {
    }
    my $el = [$ev];
    push(@$node, $el);
}
sub S {shift->start_event(@_)}
sub s {shift->start_event(@_)}

sub evbody {
    my $self = shift;
    foreach my $arg (@_) {
        if (ref($arg)) {
            $self->event(@$arg);
        }
        else {
            my $node = $self->{node};
            my $el = $node->[$#{$node}];
            confess unless $el;
	    if (@$el == 1) {
		$el->[1] = $arg;
	    }
	    else {
		my $txt_elt_name = $el->[0] . "-text";
		push(@{$el->[1]}, [$txt_elt_name=>$arg]);
	    }
        }
    }
    return;
}
sub B {shift->evbody(@_)}
sub b {shift->evbody(@_)}

# end_event is called at the end of any event;
# equivalent to the event fired at the closing of any
# xml </tag> in a SAX parser

# action: checks for method of name e_EVENTNAME()
# calls it if it is present
sub end_event {
    my $self = shift;
    my $ev = shift;
#    my $stack = $self->{evstack};
#    my $last = pop @$stack;
    my $m = perlify("e_$ev");
#    print STDERR "m=$m\n";
    my $node = $self->node;
    my $topnode = pop @$node;
    my $topnodeval = $topnode->[1];

    if ($self->can("flatten_elts") &&
        grep {$ev eq $_} $self->flatten_elts) {

        if (ref($topnodeval)) {
            my $el = $node->[$#{$node}];
######      push(@{$el->[1]}, [$ev, $topnodeval->[0]->[1]]);
            my $subevent = $topnodeval->[0]->[0];
            foreach my $subtree (@$topnodeval) {
                if ($subtree->[0] ne $subevent) {
                    use Data::Dumper;
                    print Dumper $topnodeval;
                    $self->throw("can't flatten $ev because $subtree->[0] ne $subevent");
                }
                push(@{$el->[1]}, [$ev, $subtree->[1]]);
            }
        }
    }
    elsif ($self->can("raise_elts") &&
        grep {$ev eq $_} $self->raise_elts) {

        if (ref($topnodeval)) {
            my $el = $node->[$#{$node}];
            my $subevent = $topnodeval->[0]->[0];
            foreach my $subtree (@$topnodeval) {
                if ($subtree->[0] ne $subevent) {
                    use Data::Dumper;
                    print Dumper $topnodeval;
                    $self->throw("can't flatten $ev because $subtree->[0] ne $subevent");
                }
                push(@{$el->[1]}, [$subtree->[0], $subtree->[1]]);
            }
###            push(@{$el->[1]}, [$topnodeval->[0]->[0],
###                               $topnodeval->[0]->[1]]);
        }

    }
    elsif ($self->can("kill_elts") &&
           grep {$ev eq $_} $self->kill_elts) {
        # do nothing
    }
    elsif ($self->can("multivalued_elts") &&
        grep {$ev eq $_} $self->multivalued_elts) {

        if (ref($topnodeval)) {
            my $el = $node->[$#{$node}];

#            push(@{$el->[1]}, [$ev, $topnodeval->[0]->[1]]);
            my $new =  [map {[$ev, [$_]]} @{$topnodeval}];
#            use Data::Dumper;
#            print Dumper $topnodeval;
#            print Dumper $new;
            push(@{$el->[1]},@$new);
        }

    }
    elsif ($self->can($m)) {
#        use Data::Dumper;
#        print "EV:$ev  ";
#        print Dumper $cv->[1];
        my $tree = $self->$m($topnodeval);
        my $el = $node->[$#{$node}];
        push(@{$el->[1]}, $tree) if $tree;
    }
    else {
        if ($self->can("catch_end")) {
            my $tree = $self->catch_end($ev, Data::Stag::stag_nodify($topnode));
            my $el = $node->[$#{$node}];
            push(@{$el->[1]}, $tree) if $tree;
        }
        if (@$node) {
            my $el = $node->[$#{$node}];
            if ($topnode) {
                push(@{$el->[1]}, $topnode);
                #            $el->[1] = $topnode;

            }
        }
    }
#    if (!@$node) {
        #final event
#        $self->tree($topnode);
        $self->tree(Data::Stag::stag_nodify($topnode));
#    }
    return $ev;
}
sub E {shift->end_event(@_)}
sub e {shift->end_event(@_)}


sub popnode {
    my $self = shift;
    my $node = $self->{node};
    my $topnode = pop @$node;
    return $topnode;
}

sub event {
    my $self = shift;
    my $ev = shift;
    my $st = shift;
    $self->start_event($ev);
    if (ref($st)) {
        if (ref($st) ne "ARRAY") {confess($st)}
	foreach (@$st) { 
	    confess($_) unless ref($_);
	    $self->event(@$_) 
	}
    }
    else {
	$self->evbody($st);
    }
    $self->end_event($ev);
}
*ev = \&event;


sub print {
    my $self = shift;
    print "@_";
}

sub printf {
    my $self = shift;
    printf @_;
}


sub start_element {
    my ($self, $element) = @_;

    my $name = $element->{Name};
    my $atts = $element->{Attributes};

    if (!$self->{elt_stack}) {
	$self->{elt_stack} = [];
    }
    push(@{$self->{elt_stack}}, $name);

    # check if we need an event
    # for any preceeding pcdata
    my $str = $self->{__str};
    if (defined $str) {
        $str =~ s/^\s*//;
        $str =~ s/\s*$//;
	if ($str) {
	    my $parent = $self->{elt_stack}->[-2];
	    $self->event("$parent-text", $str) if $str;
	}
	$self->{__str} = undef;
    }

    $self->start_event($name);
    foreach my $k (keys %$atts) {
        $self->event("$name-$k", $atts->{$k});
    }
#    $self->{Handler}->start_element($element);
    
}

sub characters {
    my ($self, $characters) = @_;
    my $char = $characters->{Data};
    my $str = $self->{__str};
    if ($char) {
        $str = "" if !defined $str;
        $str .= $char;
    }
#    printf STDERR "[%d]", length($self->{__str});
#    printf STDERR ".";
    $self->{__str} = $str;
#    $self->{Handler}->characters($characters);
    return;
}

sub end_element {
    my ($self, $element) = @_;
    my $name = $element->{Name};
    my $str = $self->{__str};
    pop(@{$self->{elt_stack}});
    if (defined $str) {
        $str =~ s/^\s*//;
        $str =~ s/\s*$//;
        $self->evbody($str) if $str;
    }
    $self->end_event($name);
    $self->{__str} = undef;
#    $self->{Handler}->end_element($element);
}

sub start_document {
}

sub end_document {
}


1;
