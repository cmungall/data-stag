# $Id: BaseHandler.pm,v 1.14 2003/08/12 03:39:39 cmungall Exp $
#
# This  module is maintained by Chris Mungall <cjm@fruitfly.org>

=head1 NAME

  Data::Stag::BaseHandler     - Base class for writing tag stream handlers

=head1 SYNOPSIS

  package MyPersonHandler;
  use base qw(Data::Stag::BaseHandler);


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

use vars qw($VERSION);
$VERSION="0.03";


=head3 tree (stag)

       Title: tree
     Synonym: stag

        Args: 
      Return: L<Data::Stag>
     Example: print $parser->handler->tree->xml;

returns the tree that was built from all uncaught events

=cut

sub tree {
    my $self = shift;
    $self->{_tree} = shift if @_;
    return $self->{_tree} || [];
}
*stag = \&tree;


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

sub trap_h {
    my $self = shift;
    $self->{_trap_h} = shift if @_;
    return $self->{_trap_h};
}

sub catch_end_sub {
    my $self = shift;
    $self->{_catch_end_sub} = shift if @_;
    return $self->{_catch_end_sub};
}


sub elt_stack {
    my $self = shift;
    $self->{elt_stack} = shift if @_;
    return $self->{elt_stack};
}

sub in {
    my $self = shift;
    my $in = shift;
    return 1 if grep {$in eq $_} @{$self->elt_stack};
}

sub depth {
    my $self = shift;
    return scalar(@{$self->elt_stack});
}


sub node {
    my $self = shift;
    $self->{node} = shift if @_;
    return $self->{node};
}

sub remove_elts {
    my $self = shift;
    $self->{_remove_elts} = [@_] if @_;
    return @{$self->{_remove_elts} || []};
}
*kill_elts = \&remove_elts;

sub flatten_elts {
    my $self = shift;
    $self->{_flatten_elts} = [@_] if @_;
    return @{$self->{_flatten_elts} || []};
}

sub skip_elts {
    my $self = shift;
    $self->{_skip_elts} = [@_] if @_;
    return @{$self->{_skip_elts} || []};
}
*raise_elts = \&skip_elts;

sub rename_elts {
    my $self = shift;
    $self->{_rename_elts} = {@_} if @_;
    return %{$self->{_rename_elts} || {}};
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

    if ($self->can("catch_start")) {
        $self->catch_start($ev);
    }
    if ($self->can($m)) {
        $self->$m($ev);
    }
    else {
    }

    my $stack = $self->elt_stack;
    push(@$stack, $ev);

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
	    $el->[1] = $arg;
#	    if (@$el == 1) {
#		$el->[1] = $arg;
#	    }
#	    else {
#		my $txt_elt_name = $el->[0] . "-text";
#		push(@{$el->[1]}, [$txt_elt_name=>$arg]);
#	    }
        }
    }
    return;
}
sub B {shift->evbody(@_)}
sub b {shift->evbody(@_)}

sub up {
    my $self = shift;
    my $dist = shift || 1;
    my $node = $self->node->[-$dist];
    return Data::Stag::stag_nodify($node);
}

sub up_to {
    my $self = shift;
    my $n = shift || confess "must specify node name";
    my $nodes = $self->node || [];
    my ($node) = grep {$_->[0] eq $n} @$nodes;
    confess " no such node name as $n; valid names are:".
      join(", ", map {$_->[0]} @$nodes)
	unless $node;
    return Data::Stag::stag_nodify($node);
}

# end_event is called at the end of any event;
# equivalent to the event fired at the closing of any
# xml </tag> in a SAX parser

# action: checks for method of name e_EVENTNAME()
# calls it if it is present
sub end_event {
    my $self = shift;
    my $ev = shift;
    my $stack = $self->elt_stack;
    pop(@$stack);

    my $path = join('/', @$stack);

    my $node = $self->node;
    my $topnode = pop @$node;

    my %rename = $self->rename_elts;
    if ($rename{$ev}) {
        $ev = $rename{$ev};
        $topnode->[0] = $ev;
    }
    
    my $m = perlify("e_$ev");
    if (!ref($topnode)) {
	confess("ASSERTION ERROR: $topnode not an array");
    }
    my $check = scalar(@$topnode);
    if ($check < 2) {
        # NULLs are treated the same as
        # empty strings
        # [if we have empty tags <abcde></abcde>
        #  then no evbody will be called - we have to
        #  fill in the equivalent of a null evbody here]
        push(@$topnode, '');
    }
    elsif ($check < 2) {
        confess("ASSERTION ERROR: all events must be paired; @$topnode");
    }
    else {
        # all ok
    }
    my $topnodeval = $topnode->[1];

    my $trap_h = $self->trap_h;
    if ($trap_h) {
	my $trapped_ev = $ev;
	my @P = @$stack;
	while (!$trap_h->{$trapped_ev} && scalar(@P)) {
	    my $next = pop @P;
	    $trapped_ev = "$next/$trapped_ev";
	}

	if ($trap_h->{$trapped_ev}) {
	    # call anonymous subroutine supplied in hash
	    my @trees = $trap_h->{$trapped_ev}->($self, Data::Stag::stag_nodify($topnode));
	    if (@trees) {
		if (@trees == 1 && !$trees[0]) {
#		    return;
		}
		else {
		    my $el = $node->[$#{$node}];
		    foreach my $tree (@trees) {
			push(@{$el->[1]}, $tree) if $tree && $tree->[0];
		    }
		    return;
		}
	    }
	}
    }

    if ($self->can("flatten_elts") &&
        grep {$ev eq $_} $self->flatten_elts) {

        if (ref($topnodeval)) {
            my $el = $node->[$#{$node}];
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

            my $new =  [map {[$ev, [$_]]} @{$topnodeval}];
            push(@{$el->[1]},@$new);
        }

    }
    elsif ($self->can($m)) {
#        my $tree = $self->$m($topnodeval);
        my $tree = $self->$m(Data::Stag::stag_nodify($topnode));

    }
    else {
        if ($self->can("catch_end")) {
            $self->catch_end($ev, Data::Stag::stag_nodify($topnode));
        }
        if ($self->catch_end_sub) {
            $self->catch_end_sub->($self, Data::Stag::stag_nodify($topnode));
        }
        if (@$node) {
            my $el = $node->[$#{$node}];
            if ($topnode) {
                if (@$topnode) {
                    if (!$el->[1]) {
#                        print STDERR "*** adding el to $el->[0]...\n";
#                        use Data::Dumper;
#                        print Dumper $node;
                        $el->[1] = [];
                    }
                    push(@{$el->[1]}, $topnode);
                }
            }
        }
    }
#    if (!@$node) {
        #final event
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
#	    use Data::Dumper;
#	    print Dumper $st;
	    confess("$ev $st $_") unless ref($_);
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

    if (!$self->{sax_elt_stack}) {
	$self->{sax_elt_stack} = [];
    }
    push(@{$self->{sax_elt_stack}}, $name);
    push(@{$self->{is_nonterminal_stack}}, 0);
    if (@{$self->{is_nonterminal_stack}} > 1) {
	$self->{is_nonterminal_stack}->[-2] = 1;
    }

    # check if we need an event
    # for any preceeding pcdata
    my $str = $self->{__str};
    if (defined $str) {
        $str =~ s/^\s*//;
        $str =~ s/\s*$//;
	if ($str) {
	    my $parent = $self->{sax_elt_stack}->[-2];
	    $self->event("$parent-text", $str) if $str;
	}
	$self->{__str} = undef;
    }

    $self->start_event($name);
    foreach my $k (keys %$atts) {
        $self->event("$name-$k", $atts->{$k});
	$self->{is_nonterminal_stack}->[-1] = 1;
    }
#    $self->{Handler}->start_element($element);
    
}

sub characters {
    my ($self, $characters) = @_;
    my $char = $characters->{Data};
    my $str = $self->{__str};
    if (defined $char) {
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
    my $parent = pop(@{$self->{sax_elt_stack}});
    my $is_nt = pop(@{$self->{is_nonterminal_stack}});
    if (defined $str) {
        $str =~ s/^\s*//;
        $str =~ s/\s*$//;
	if ($str || $str eq '0') {
	    if ($is_nt) {
		$self->event($parent . "-text" =>
			     $str);
			     
	    }
	    else {
		$self->evbody($str);
	    }
	}
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
