# $Id: StagImpl.pm,v 1.3 2002/12/06 23:57:21 cmungall Exp $
#
# Author: Chris Mungall <cjm@fruitfly.org>
#
# You may distribute this module under the same terms as perl itself

package Data::Stag::StagImpl;

=head1 NAME

  Data::Stag::StagImpl

=head1 SYNOPSIS

  use Data::Stag qw(:all);

=cut

use Carp;
use strict;
use vars qw($AUTOLOAD $DEBUG);
use Data::Stag::Base;
use Data::Stag::Util qw(rearrange);
use base qw(Data::Stag::StagI);

use vars qw($VERSION);
$VERSION="0.01";


sub new {
    my $class = shift;
    if (@_ == 2 || @_ == 0) {
        return bless [@_], $class;
    }
    else {
        confess @_;
    }
}

sub unflatten {
    my $tree = shift || [];
    my @intree = @_;
    my @outtree = ();
    while (@intree) {
        my $k = shift @intree;
        my $v = shift @intree;
        if (ref($v)) {
            $v = [unflatten(@$v)];
        }
        push(@outtree,
             [$k=>$v]);
    }
    @$tree = @outtree;
    return $tree;
}

sub load_module {

    my $classname = shift;
    confess unless $classname;
    my $mod = $classname;
    $mod =~ s/::/\//g;

    if (!$mod) {
        confess("must supply as mod as argument");
    }

    if ($main::{"_<$mod.pm"}) {
    }
    else {
        require "$mod.pm";
    }
}

# -------------------------------------
# ----   INPUT/OUTPUT FUNCTIONS   -----
# -------------------------------------


sub parser {
    my $tree = shift;
    my ($fn, $fmt, $h, $str, $fh) = 
      rearrange([qw(file format handler str fh)], @_);
    if (!$fmt) {
	if ($fn =~ /\.xml$/) {
            $fmt = "xml";
        }
        elsif ($fn =~ /\.ite?xt$/) {
            $fmt = "itext";
        }
        elsif ($fn =~ /\.se?xpr$/) {
            $fmt = "sxpr";
        }
        elsif ($fn =~ /\.el$/) {
            $fmt = "sxpr";
        }
        elsif ($fn =~ /\.pl$/) {
            $fmt = "perl";
        }
        elsif ($fn =~ /\.perl$/) {
            $fmt = "perl";
        }
        else {
            # default to xml
            $fmt = "xml";
        }
    }
    my $parser;
    if ($fmt =~ /::/) {
        load_module($fmt);
        $fmt = $fmt->new;
    }
    if (ref $fmt) {
        $parser = $fmt;
    }
    elsif ($fmt eq "xml") {
        $parser = "Data::Stag::XMLParser";
    }
    elsif ($fmt eq "itext") {
        $parser = "Data::Stag::ITextParser";
    }
    elsif ($fmt eq "perl") {
        $parser = "Data::Stag::PerlParser";
    }
    elsif ($fmt eq "sxpr") {
        $parser = "Data::Stag::SxprParser";
    }
    else {
    }
    load_module($parser);
    my $p = $parser->new;
    return $p;
}

sub parse {
    my $tree = shift;
    my ($fn, $fmt, $h, $str, $fh) = 
      rearrange([qw(file format handler str fh)], @_);

    if (!$tree || !ref($tree)) {
        $tree = [];
    }

    my $p = parser($tree, @_);
    $h = Data::Stag::Base->new unless $h;
    $p->handler($h);
    $p->parse(
              -file=>$fn,
              -str=>$str,
              -fh=>$fh,
             );
    Nodify($h->tree);
    @$tree = @{$h->tree || []};
    return $h->tree;
}
*parseFile = \&parse;

sub from {
    my $class = shift;
    my ($fmt, $file, $str) = 
      rearrange([qw(fmt file str)], @_);
    if ($fmt eq 'xmlstr') {
        return xmlstr2tree($file);
    }
    elsif ($fmt =~ /(.*)str/) {
        $fmt = $1;
        return parse([], 
                     -str=>$file,
                     -format=>$fmt);
        
    }
    elsif ($fmt eq 'xml') {
        return xml2tree($file);
    }
    else {
        return parse([], 
                     -file=>$file,
                     -format=>$fmt);
    }
}

sub write {
    my $tree = shift || [];
    my ($fn, $fmt, @args) = @_;
    if (!$fmt) {
	if (!$fn) {
	    $fmt = "xml";
	}
        elsif ($fn =~ /\.xml$/) {
            $fmt = "xml";
        }
        elsif ($fn =~ /\.ite?xt$/) {
            $fmt = "itext";
        }
        else {
        }
    }
    my $writer;
    if ($fmt eq "xml") {
        $writer = "Data::Stag::XMLWriter";
    }
    elsif ($fmt eq "itext") {
        $writer = "Data::Stag::ITextWriter";
    }
    else {
    }
    load_module($writer);
    my $w = $writer->new($fn);
    $w->event(@$tree);
    return;
}

sub hash {
    my $tree = shift;
    my ($ev, $subtree) = @$tree;
    if (ref($subtree)) {
        my @h = map { tree2hash($_) } @$subtree;
        my %h = ();
        while (@h) {
            my $k = shift @h;
            my $v = shift @h;
#            print STDERR "$k = $v;; [@h]\n";
            $h{$k} = [] unless $h{$k};
            push(@{$h{$k}}, @$v);
        }
        return $ev => [{%h}];
#        return [map { tree2hash($_) } @$subtree];
    }
    else {
        return $ev=>[$subtree];
    }
}
*tree2hash = \&hash;

# this FLATTENS everything
# any non terminal node is flattened and lost
# does not check for duplicates!
sub pairs {
    my $tree = shift;
    my ($ev, $subtree) = @$tree;
    if (ref($subtree)) {
        my @pairs = map { tree2pairs($_) } @$subtree;
        return (@pairs);
#        return [map { tree2hash($_) } @$subtree];
    }
    else {
        return ($ev=>$subtree);
    }
}
*tree2pairs = \&pairs;

# PRIVATE
sub tab {
    my $t=shift;
    return "  " x $t;
}

sub xml {
    my $tree = shift;
    my $indent = shift || 0;
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($ev, $subtree) = @$tree;
    if (ref($subtree)) {
        return 
          sprintf("%s<$ev>\n%s%s</$ev>\n",
                  tab($indent++),
                  join("", map { xml($_, $indent) } @$subtree),
                  tab($indent-1),
                 );
    }
    else {
	my $txt =
		   xmlesc($subtree) || "";
	if (length($txt) > 60 ||
	    $txt =~ /\n/) {
	    $txt .= "\n" unless $txt =~ /\n$/s;
	    $txt = "\n$txt" unless $txt =~ /^\n/;
	    $txt .= tab($indent);
	}
        return
          sprintf("%s<$ev>%s</$ev>\n",
                  tab($indent),
		  $txt
		 );
    }
}
*tree2xml = \&xml;

sub perldump {
    my $tree = shift;
    return 
      _tree2perldump($tree, 1) . ";\n";
}
*tree2perldump = \&perldump;

sub _tree2perldump {
    my $tree = shift;
    my $indent = shift || 0;
    my ($ev, $subtree) = @$tree;
    if (ref($subtree)) {
	$indent++;
        return 
          sprintf("%s[ '$ev' => [\n%s%s]]",
#                  tab($indent++),
		  "",
                  join(",\n", map {
		      tab($indent) .
			_tree2perldump($_, $indent)
		  } @$subtree),
#                  tab($indent-1),
		  "",
                 );
    }
    else {
        return
          sprintf("%s[ '$ev' => %s ]",
#                  tab($indent),
		  "",
                  perlesc($subtree) || "");
    }
}

sub perlesc {
    my $val = shift;
    return "undef" if !defined $val;
    $val =~ s/\'/\\\'/g;
    return "'$val'";
}

sub sax {
    my $tree = shift;
    my $saxhandler = shift;
    $saxhandler->start_document;
    _tree2sax($tree, $saxhandler);
    $saxhandler->end_document;
}
*tree2sax = \&sax;

sub _tree2sax {
    my $tree = shift;
    my $saxhandler = shift;
    my ($ev, $subtree) = @$tree;
    $saxhandler->start_element({Name => $ev});
    if (ref($subtree)) {
        map { _tree2sax($_, $saxhandler) } @$subtree;
    }
    else {
        $saxhandler->characters({Data => $subtree});
        
    }
    $saxhandler->end_element({Name => $ev});
}

sub events {
    my $tree = shift;
    my $handler = shift;
    $handler->event(@$tree);
}

sub xmlesc {
    my $word = shift;
    return unless $word;
    $word =~ s/\&/\&amp;/g;
    $word =~ s/\</\&lt;/g;
    $word =~ s/\>/\&gt;/g;
    return $word;
    
}

sub xml2tree {
    my $file = shift;
    my $handler = Data::Stag::Base->new;
    my $parser = XML::Parser::PerlSAX->new();
    my %parser_args = (Source => {SystemId => $file},
                       Handler => $handler);
    $parser->parse(%parser_args);
    return Node(@{$handler->tree});
}

sub xmlstr2tree {
    my $str = shift;
    my $handler = Data::Stag::Base->new;
    my $parser = XML::Parser::PerlSAX->new();
    my %parser_args = (Source => {String => $str},
                       Handler => $handler);
    $parser->parse(%parser_args);
    return Node(@{$handler->tree});
}

# WANTARRAY
sub sxpr2tree {
    my $sxpr = shift;
    my $indent = shift || 0;
    my $i=0;
    my @args = ();
    while ($i < length($sxpr)) {
        my $c = substr($sxpr, $i, 1);
        print STDERR "c;$c i=$i\n";
        $i++;
        if ($c eq ')') {
            my $funcnode = shift @args;
            print STDERR "f = $funcnode->[1]\n";
            map {print xml($_)} @args;
            return [$funcnode->[1] =>[@args]], $i;
        }
        if ($c =~ /\s/) {
            next;
        }
        if ($c eq '(') {
            my ($tree, $extra) = sxpr2tree(substr($sxpr, $i), $indent+1);
            push(@args, $tree);
            $i += $extra;
            printf STDERR "tail: %s\n", substr($sxpr, $i);
        }
        else {
            # look ahead
            my $v = "$c";
            my $p=0;
            while ($i+$p < length($sxpr)) {
                my $c = substr($sxpr, $i+$p, 1);
                if ($c =~ /\s/) {
                    last;
                }
                if ($c eq '(') {
                    last;
                }
                if ($c eq ')') {
                    last;
                }
                $p++;
                $v.= $c;
            }
            $i+=$p;
            push(@args, [arg=>$v]);
        }
    }
#    map {print xml($_)} @args;
    map {Nodify($_)} @args;
    if (wantarray) {
        return @args;
    }
    
    return $args[0];
}

sub addkid {
    my $tree = shift;
    my $newtree = shift;
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($ev, $subtree) = @$tree;
    push(@$subtree, $newtree);
    $newtree;
}
*addChildTree = \&addkid;
*addchild = \&addkid;
*ak = \&addkid;

#sub findChildren {
#    my $tree = shift;
#    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
#    my ($ev, $subtree) = @$tree;
#    return @$subtree;
#}

sub findnode {
    my $tree = shift;
    my $node = shift;

    my $replace = shift;
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($ev, $subtree) = @$tree;
    if ($DEBUG) {
        print STDERR "$ev, $subtree;; replace = $replace\n";
    }
    if (test_eq($ev, $node)) {
        if ($DEBUG) {
            print STDERR "  MATCH\n";
        }
        if (defined $replace) {
            my @old = @$tree;
            @$tree = @$replace;
            return [@old];
        }
#        return [$ev=>$subtree] ;
        return $tree ;
    }
    return unless ref($subtree);
    my @nextlevel =
      map { 
          map {
              Nodify($_)
          } findnode($_, $node, $replace);
          
      } @$subtree;
    # get rid of empty nodes
    # (can be caused by replacing)
    @$subtree = map { ref($_) && !scalar(@$_) ? () : $_ } @$subtree;
#    if (wantarray) {
#        return $nextlevel[0];
#    }
    return @nextlevel;
}
*fn = \&findnode;
*findSubTree = \&findnode;
*fst = \&findnode;

sub set {
    my $tree = shift || confess;
    my $node = shift;
    my @replace = @_;
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($ev, $subtree) = @$tree;
    my $is_set;
    my @nu = ();
    foreach my $st (@$subtree) {
        push(@nu, $st);
        my ($ev, $subtree) = @$st;
        if (test_eq($ev, $node)) {
            if (!$is_set) {
                pop @nu;
                push(@nu,
                     map {
                         [$node => $_]
                     } @replace);
                $is_set = 1;
            }
            else {
                pop @nu;
            }
        }
    }
    
    # place at the end if not already present
    if (!$is_set) {
        map {
            addChildTree($tree, [$node=>$_]);
        } @replace;
    }
    else {
        @$tree = ($ev, \@nu);
    }
    return @replace;
}
*s = \&set;
*setSubTreeVal = \&set;

sub setnode {
    my $tree = shift;
    my $elt = shift;
    my $nunode = shift;
    set($tree, $elt, $nunode->data); 
}

sub add {
    my $tree = shift || confess;
    my $node = shift;
    my @v = @_;
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($ev, $subtree) = @$tree;
    my @nu_subtree = ();
    my $has_been_set = 0;
    for (my $i=0; $i<@$subtree; $i++) {
	my $st = $subtree->[$i];
	my $next_st = $subtree->[$i+1];
        my ($ev, $subtree) = @$st;
	push(@nu_subtree, $st);
        if (test_eq($ev, $node) &&
	    (!$next_st ||
	     $next_st->[0] ne $ev)) {
	    push(@nu_subtree, 
		 map { [$ev=>$_] } @v);
	    $has_been_set = 1;
	}
    }
    if (!$has_been_set) {
	map {
	    addChildTree($tree, [$node=>$_]); 
	} @v;
    }
    else {
	@$subtree = @nu_subtree;
    }
    return;
}
*a = \&add;
*addSubTreeVal = \&add;

sub unset {
    my $tree = shift || confess;
    my $node = shift;
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($ev, $subtree) = @$tree;
    my @nu_tree = ();
    foreach my $st (@$subtree) {
        my ($ev, $subtree) = @$st;
        if ($ev ne $node) {
            push(@nu_tree, $st);
        }
    }
    $tree->[1] = \@nu_tree;
    return;
}
*unsetSubTreeVal = \&unset;
*u = \&unset;


# WANTARRAY
sub findval {
    my $tree = shift || confess;
    my ($node, @path) = splitpath(shift);
    my $replace = shift;

    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);

    my @r = ();
    if (@path) {
        @r = map { $_->findval(\@path, $replace) } findnode($tree, $node)
    }
    else {
        my ($ev, $subtree) = @$tree;
        if (test_eq($ev, $node)) {
            if (defined $replace)  {
                $tree->[1] = $replace;
            }
            return $subtree;
        }
        return unless ref($subtree);
        @r = map { findval($_, $node, $replace) } @$subtree;
    }
    if (wantarray) {
        return @r;
    }
    $r[0];
}
*fv = \&findval;
*findSubTreeVal = \&findval;

# WANTARRAY
sub get {
    my $tree = shift || confess;
    my ($node, @path) = splitpath(shift);
    my $replace = shift;

    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);

    my @v = ();
    if (@path) {
        @v = map { $_->get(\@path, $replace) } getnode($tree, $node)
    }
    else {

        my ($top_ev, $children) = @$tree;
        @v = ();
        foreach my $child (@$children) {
            confess unless ref $child;
            my ($ev, $subtree) = @$child;
            if (test_eq($ev, $node)) {
                if (defined $replace)  {
                    $tree->[1] = $replace;
                }
                push(@v, $subtree);
            }
        }
    }
    if (wantarray) {
        return @v;
    }
    $v[0];
}
*g = \&get;

# WANTARRAY
sub getnode {
    my $tree = shift || confess;
    my ($node, @path) = splitpath(shift);
    my $replace = shift;

    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);

    my @v = ();
    if (@path) {
        @v = map { $_->getnode(\@path, $replace) } getnode($tree, $node)
    }
    else {

        my ($top_ev, $children) = @$tree;
        foreach my $child (@$children) {
            my ($ev, $subtree) = @$child;
            if (test_eq($ev, $node)) {
                if (defined $replace)  {
                    $tree->[1] = $replace;
                }
                push(@v, Nodify($child));
            }
        }
    }

    if (wantarray) {
        return @v;
    }
    $v[0];
}
*getn = \&getnode;
*gn = \&getnode;
*gettree = \&getnode;

sub sgetnode {
    my $tree = shift;
    my @v = getnode($tree, @_);
    return $v[0];
}
*sgetn = \&sgetnode;
*sgn = \&sgetnode;
*sgettree = \&sgetnode;


sub getl {
    my $tree = shift || confess;
    my @elts = @_;
    my %elth = map{$_=>1} @elts;
    my %valh = ();
    confess("problem: $tree not arr") unless ref($tree) && ref($tree) eq "ARRAY" || isaNode($tree);
    my ($top_ev, $children) = @$tree;
    my @v = ();
    foreach my $child (@$children) {
        my ($ev, $subtree) = @$child;
        if ($elth{$ev}) {
            # warn if dupl?
            $valh{$ev} = $subtree;
        }
    }
    return map {$valh{$_}} @elts;
}
*getlist = \&getl;
*gl = \&getl;

sub sget {
    my $tree = shift;
    my @v = get($tree, @_);
    # warn if multivalued?
    return $v[0];
}
*sg = \&sget;

sub sfindval {
    my $tree = shift;
    my @v = findval($tree, @_);
    # warn if multivalued?
    return $v[0];
}
*sfv = \&sfindval;
*singlevalFindSubTreeVal = \&sfindval;

# private
sub indexOn {
    my $tree = shift;
    my $key = shift;

    my %h = ();
    my ($evParent, $stParent) = @$tree;
    foreach my $subtree (@$stParent) {
	my @vl = get($subtree, $key);
	foreach my $v (@vl) {
	    if (!$h{$v}) { $h{$v} = [] }
	    push(@{$h{$v}}, $subtree);
	}
    }
    return \%h;
}

# does a relational style join
sub njoin {
    my $tree = shift;
    my $element = shift;      # name of element to join
    my $key = shift;          # name of join element
    my $searchstruct = shift; # structure
    my @elts = $tree->fst($element);
    map { paste($_, $key, $searchstruct) } @elts;
    return;
}
*nj = \&njoin;
*j = \&njoin;

sub paste {
    my $tree = shift;
    my $key = shift;
    my $searchstruct = shift;
    # use indexing?
    my $ssidx = indexOn($searchstruct, $key);

    my ($evParent, $stParent) = @$tree;
    my @children = ();
    foreach my $subtree (@$stParent) {
	my @nu = ($subtree);
	my ($ev, $st) = @$subtree;
	if ($ev eq $key) {
	    $tree->throw("can't join on $ev - $st is not primitive")
	      if ref $st;
	    my $replace = $ssidx->{$st} || [];
	    @nu = @$replace;
	}
	push(@children, @nu);
    }
    @$tree = ($evParent, \@children);
    return;
}

# iterate depth first through tree executing code
sub iterate {
    my $tree = shift;
    my $code = shift;
    my $parent = shift;
    $code->($tree, $parent);
    my @subnodes = $tree->subnodes;
    foreach (@subnodes) {
        iterate($_, $code, $tree);
    }
    return;
}
*i = \&iterate;

# takes a denormalized flat table of rows/columns
# and turns it back into its original tree structure;
# useful for querying databases
sub normalize {
    my $tree = shift || [];
    my ($schema,
        $rows,
        $top,
        $cols,
        $constraints,
        $path) =
          rearrange([qw(schema
                        rows
                        top
                        cols
                        constraints
                        path)], @_);
    if (!$schema) {
        $schema = $tree->new(schema=>[]);
    }
    if (!isaNode($schema)) {
        if (!ref($schema)) {
            # it's a string - parse it
            # (assume sxpr)
        }
        $schema = $tree->from('sxprstr', $schema);
    }
    # TOP - this is the element name
    # to group the structs under.
    # [override if specified explicitly]
    if ($top) {
        $schema->set_top($top);
    }
    $top = $schema->get_top || "set";
    my $topstruct = $tree->new($top, []);

    # COLS - this is the columns (attribute names)
    # in the order they appear
    # [override if specified explicitly]
    if ($cols) {
        my @ncols =
          map {
              if (ref($_)) {
                  $_
              }
              else {
                  # presume it's a string
                  # format = GROUP.ATTRIBUTENAME
                  if (/(\w+)\.(\w+)/) {
                      $tree->new(col=>[
                                       [group=>$1],
                                       [name=>$2]]);
                  }
                  else {
                      confess $_;
                  }
              }
          } @$cols;
        $schema->set_cols([@ncols]);
    }


    # PATH - this is the tree structure in
    # which the groups are structured
    # [override if specified explicitly]
    if ($path) {
        if (ref($path)) {
        }
        else {
            $path = $tree->from('sxprstr', $path);
        }
        $schema->set_path([$path]);
    }
    $path = $schema->sgetnode_path;
    if (!$path) {
        confess("no path!");
    }
    
    # column headings
    my @cols = $schema->sgetnode_cols->getnode_col();

    # set the primary key for each group;
    # the default is all the columns in that group
    my %pkey_by_groupname = ();
    my %cols_by_groupname = ();
    foreach my $col (@cols) {
        my $groupname = $col->get_group;
        my $colname = $col->get_name;
        $pkey_by_groupname{$groupname} = []
          unless $pkey_by_groupname{$groupname};
        push(@{$pkey_by_groupname{$groupname}},
             $colname);
        $cols_by_groupname{$groupname} = []
          unless $cols_by_groupname{$groupname};
        push(@{$cols_by_groupname{$groupname}},
             $colname);
    }
    my @groupnames = keys %pkey_by_groupname;

    # override PK if set as a constraint
    my @pks = $schema->findnode("primarykey");
    foreach my $pk (@pks) {
        my $groupname = $pk->get_group;
        my @cols = $pk->get_col;
        $pkey_by_groupname{$groupname} = [@cols];
    }

    # ------------------
    #
    # loop through denormalised rows,
    # grouping the columns into their
    # respecive groups
    #
    # eg
    #
    #  <----- a ----->   <-- b -->
    #  a.1   a.2   a.3   b.1   b.2
    #
    # algorithm:
    #  use path/tree to walk through
    #
    # ------------------

    # keep a hash of all groups by their primary key vals
    #  outer key = groupname
    #  inner key = pkval
    #  hash val  = group structure
    my %all_group_hh = ();
    foreach my $groupname (@groupnames) {
        $all_group_hh{$groupname} = {};
    }

    # keep an array of all groups
    #  outer key = groupname
    #  inner array = ordered list of groups
#    my %all_group_ah = ();
#    foreach my $groupname (keys %pkey_by_groupname) {
#        $all_group_ah{$groupname} = [];
#    }

    my ($first_in_path) = $path->subnodes;
    my $top_record_h = 
      {
       child_h=>{
                 $first_in_path->name=>{}
                },
       struct=>$topstruct
      };
    # loop through rows
    foreach my $row (@$rows) {
        my @colvals = @$row;

        # keep a record of all groups in
        # this row
        my %current_group_h = ();
        for (my $i=0; $i<@cols; $i++) {
            my $colval = $colvals[$i];
            my $col = $cols[$i];
            my $groupname = $col->get_group;
            my $colname = $col->get_name;
            my $group = $current_group_h{$groupname};
            if (!$group) {
                $group = {};
                $current_group_h{$groupname} = $group;
            }
            $group->{$colname} = $colval;
        }

        # we now have a hash of hashes -
        #  outer keyed by group id
        #  inner keyed by group attribute name
        
        # traverse depth first down path;
        # add new nodes as children of the parent
        sub make_a_tree {
            my $class = shift;
            my $parent_rec_h = shift;
            my $node = shift;
            my %current_group_h= %{shift ||{}};
            my %pkey_by_groupname = %{shift ||{}};
            my %cols_by_groupname = %{shift ||{}};
            my $groupname = $node->name;
            my $grouprec = $current_group_h{$groupname};
            my $pkcols = $pkey_by_groupname{$groupname};
            my $pkval = 
              CORE::join("\t",
                         map {
                             esctab($grouprec->{$_})
                         } @$pkcols);
            my $rec = $parent_rec_h->{child_h}->{$groupname}->{$pkval};
            if (!$rec) {
                my $groupcols = $cols_by_groupname{$groupname};
                my $groupstruct =
                  $class->new($groupname=>[
                                          map {
                                              [$_ => $grouprec->{$_}]
                                          } @$groupcols
                                         ]);
                my $parent_groupstruct = $parent_rec_h->{struct};
                if (!$parent_groupstruct) {
                    confess("no parent for $groupname");
                }
                add($parent_groupstruct,
                    $groupstruct->name,
                    $groupstruct->data);
                $rec =
                  {struct=>$groupstruct,
                   child_h=>{}};
                foreach ($node->subnodes) {
                    # keep index of children by PK
                    $rec->{child_h}->{$_->name} = {};
                }
                $parent_rec_h->{child_h}->{$groupname}->{$pkval} = $rec;
            }
            foreach ($node->subnodes) {
                make_a_tree($class,
                            $rec, $_, \%current_group_h,
                            \%pkey_by_groupname, \%cols_by_groupname);
            }
        }
        make_a_tree($tree,
                    $top_record_h, $first_in_path, \%current_group_h,
                    \%pkey_by_groupname, \%cols_by_groupname);
    }
    return $topstruct;
}
*norm = \&normalize;
*normalise = \&normalize;


sub esctab {
    my $w=shift;
    $w =~ s/\t/__MAGICTAB__/g;
    $w;
}

sub findvallist {
    my $tree = shift || confess;
    my @nodes = @_;
    my @vals =
      map {
          my @v = findval($tree, $_);
          if (@v > 1) {
              confess(">1 val for $_: @v");
          }
          $v[0];
      } @nodes;
    return @vals;
}
*findSubTreeValList = \&findvallist;
*fvl = \&findvallist;

sub findChildVal {
    confess("deprecated - use get");
    my $tree = shift;
    my $node = shift;
    my $replace = shift;
    confess unless ref($tree);
    my ($ev, $subtree) = @$tree;
    return $subtree if test_eq($ev, $node);
    return unless ref($subtree);
    my @children = grep { $_->[0] eq $node } @$subtree;
#    print "@children\n";
    if (defined $replace) {
        return 
          map { $_->[1] = $replace } @children;
    }
    my @r = map { $_->[1] } @children;
    if (wantarray) {
        return @r;
    }
    $r[0];
}

sub qmatch {
    my $tree = shift;
    my $elt = shift;
    my $matchkey = shift;
    my $matchval = shift;
    my $replace = shift;

    my @st = findnode($tree, $elt);
    my @match =
      grep {
          testSubTreeMatch($_, $matchkey, $matchval);
      } @st;
    if ($replace) {
	map {
	    @$_ = @$replace;
	} @match;
    }
    return @match;
}
*qm = \&qmatch;
*findSubTreeMatch = \&qmatch;


sub tmatch {
    my $tree = shift;
    my $elt = shift;
    my $matchval = shift;
    my @vals = findval($tree, $elt);
    return grep {$_ eq $matchval} @vals;
}
*testSubTreeMatch = \&tmatch;
*tm = \&tmatch;


sub tmatchhash {
    my $tree = shift;
    my $match = shift;
    my @mkeys = keys %$match;
    my @mvals = map {$match->{$_}} @mkeys;

    my @rvals = findvallist($tree, @mkeys);
    my $pass =  1;
    for (my $i=0; $i<@mvals; $i++) {
        $pass = 0 if $mvals[$i] ne $rvals[$i];
    }
    print "CHECK @mvals eq @rvals [$pass]\n";
    return $pass;
}
*tmh = \&tmatchhash;
*testSubTreeMatchHash = \&tmatchhash;

sub tmatchnode {
    my $tree = shift;
    my $matchtree = shift;
    my ($node, $subtree) = @$tree;
    confess unless ref $matchtree;
    my ($mnode, $msubtree) = @$matchtree;
    if ($node ne $mnode) {
        return unless ref $subtree;
        return 
          grep {
              testSubTreeMatchTree($_,
                                   $matchtree)
          } @$subtree;
    }
    if (!ref($subtree) && !ref($msubtree)) {
        return $subtree eq $msubtree;
    }
    if (ref($subtree) && ref($msubtree)) {
        my @got = ();
        for (my $i=0; $i<@$msubtree; $i++) {
            my $n = $msubtree->[$i]->[0];
            my ($x) = grep {$_->[0] eq $n} @$subtree;
            return unless $x;
            my $ok =
              testSubTreeMatchTree($x,
                                   $msubtree->[$i]);
            return unless $ok;
                                   
        }
        return 1;
    }

}
*tmn = \&tmatchnode;
*testSubTreeMatchTree = \&tmatchnode;

sub cmatch {
    my $tree = shift;
    my $node = shift;
    my $matchval = shift;
    my @vals = findval($tree, $node);
    return scalar(grep {$_ eq $matchval} @vals);
}
*cm = \&cmatch;
*countSubTreeMatch = \&cmatch;


sub where {
    my $tree = shift;
    my $node = shift;
    my $testcode = shift;
    my $replace = shift;
    my @subtrees = findnode($tree, $node);
    my @match =
      grep {
          $testcode->($_);
      } @subtrees;
    if (defined $replace) {
        map {
            @$_ = @$replace;
        } @match;
    }
    return @match;
}
*w = \&where;
*findSubTreeWhere = \&where;


#sub findSubTreeWhere {
#    my $tree = shift;
#    my $node = shift;
#    my $testcode = shift;
#    my $replace = shift;
##    use Data::Dumper;
##    print Dumper($expr);
#    my $call = $expr->name;
#    my @p = $expr->findChildVal('arg');
##    print Dumper(\@p);
#    my @subtrees = findSubTree($tree, $node);
#    no strict 'refs'; 
#    my @match =
#      grep {
#          &$call($_, @p);
#      } @subtrees;
#    if (defined $replace) {
#        map {
#            print "WAS:";
#            print xml($_);
#            print "NOW:";
#            print xml($replace);
#            @$_ = @$replace;
#        } @match;
#    }
#    return @match;
#}

sub run {
    my $tree = shift;
    my $code = shift;
    my $func = $code->name;
    my @p = $code->children();
    my @args = ();
    foreach my $p (@p) {
        if ($p->name eq 'arg') {
            if (isaNode($p->children)) {
                die;
                push(@args,
                     evalTree($tree,
                              $p->children));
                              
            }
            else {
                push(@args, $p->children);
            }
        }
        else {
            print "rcall $tree $p\n";
            push(@args,
                 evalTree($tree,
                          $p));
        }
    }
    no strict 'refs'; 
    my @r = &$func($tree, @p);
    return @r if wantarray;
    return shift @r;
}
*evalTree = \&run;


# ------------------------
# collapseElement($tree, $elt)
#
# eg if we have
#
# +personset
#    +person
#       +name jim
#       +job  sparky
#    +person
#       +name jim
#       +hair green
#    +person
#       +name eck
#       +hair blue
#
# then execute
# collapseElement($tree, 'person', 'name')
#
# we end up with 
#
# +personset
#    +person
#       +name jim
#       +job  sparky
#       +hair green
#    +person
#       +name eck
#       +hair blue
#
# OR if we have
#
# +personset
#    +person
#       +name jim
#       +job  sparky
#       +petname  bubbles
#       +pettype  chimp
#    +person
#       +name jim
#       +job  sparky
#       +petname  flossie
#       +pettype  sheep
#    +person
#       +name eck
#       +job  bus driver
#       +petname  gnasher
#       +pettype  dug
#
#
# then execute
# collapseElement($tree, 'name', 'job')
#
# we end up with 
#
# +personset
#    +person
#       +name jim
#       +job  sparky
#       +pet
#          +petname  bubbles
#          +pettype  chimp
#       +pet
#          +petname  flossie
#          +pettype  sheep
#    +person
#       +name eck
#       +job  bus driver
#       +pet
#          +petname  gnasher
#          +pettype  dug
#
#
# warning: element should be unique
# todo: allow person/name
#
# ------------------------
sub collapse {
    my $tree = shift;
    my $elt = shift;
    my $merge_elt = shift;
    my @subtrees = findnode($tree, $elt);
    my %treeh = ();
    my @elt_order = (); # preserve ordering
    map {
        my @v = findval($_, $merge_elt);
        die unless scalar(@v) == 1;
        my $val = shift @v;
        push(@elt_order, $val) unless $treeh{$val};
        $treeh{$val} = [] unless $treeh{$val};
        push(@{$treeh{$val}}, $_);
    } @subtrees;
    my @new_subtrees =
      map {
          my $trees = $treeh{$_};
          my ($v) = findval($trees->[0], $merge_elt);
          [
           $elt=>[
                  [$merge_elt=>$v],
                  map {
                      my ($ev, $subtree) = @$_;
                      grep {
                          $_->[0] ne $merge_elt
                      } @$subtree;
                  } @$trees,
                 ]
          ]
      } @elt_order;

    findnode($tree, $elt, []);
    push(@{$tree->[1]}, @new_subtrees);
    return $tree;
}
*collapseElement = \&collapse;

sub merge {
    my $tree = shift;
    my @elts = @{shift || []};
    my $merge_key = shift;

    return unless @elts;
    my $e1 = $elts[0];
    my ($type, $v) = @$e1;
    my @cur_elts = findnode($tree, $type);
    foreach my $elt (@elts) {
        my ($v) = findval($elt, $merge_key);
        foreach my $cur_elt (@cur_elts) {
            my ($cv) = findval($cur_elt, $merge_key);
            if ($cv eq $v) {
                # merge
                my $cur_children = $cur_elt->[1];
                my $children = $elt->[1];
                push(@$cur_children,
                     grep {
                         $_->[0] ne $merge_key
                     } @$children);
            }
        }0
    }
    return $tree;
}
*mergeElements = \&merge;

sub duplicate {
    my $tree = shift;
    my $xml = xml($tree);
    return xmlstr2tree($xml);
}
*d = \&duplicate;

sub isanode {
    my $node = shift;
    return UNIVERSAL::isa($node, "Data::Stag::StagI");
}
*isa_node = \&isanode;
*isaNode = \&isanode;

sub node {
    return Data::Stag::StagImpl->new(@_);
}
*Node = \&node;

sub nodify {
    my $tree = shift;
    if (!ref($tree)) {
        # allow static or nonstatic usage
        $tree = shift;
    }
    confess unless ref $tree;
    my $class = "Data::Stag::StagImpl";
    bless $tree, $class
}
*Nodify = \&nodify;

sub xpath {
    my $tree = shift;
    load_module("XML::XPath");
    my $xp = XML::XPath->new(xml=>xml($tree));
    return $xp;
}
*xp = \&xpath;
*getxpath = \&xpath;
*tree2xpath = \&xpath;


sub xpquery {
    my $tree = shift;
    my @args = @_;
    load_module("XML::XPath::XMLParser");
    my $xp = $tree->getXPath;
    my $nodeset = $xp->find(@args);
    my @nodes =
      map {
	  xmlstr2tree(XML::XPath::XMLParser::as_string($_));
      } $nodeset->get_nodelist;
    return @nodes;
}
*xpq = \&xpquery;
*xpathquery = \&xpquery;
*xpfind = \&xpquery;
*xpFind = \&xpquery;


#use overload
#  '.' => sub {my @r=findnodeVal($_[0],$_[1]);$r[0]},
#  '-' => sub {my @r=findnodeVal($_[0],$_[1]);$r[0]},
#  '+' => sub {my @r=$_[0]->findnode($_[1]);return $r[0]},
#  '/' => sub {[findnodeVal($_[0],$_[1])]},
#  '*' => sub {[$_[0]->findnode($_[1])]},
#  '<' => sub {Data::Stag::testSubTreeMatchTree($_[0], $_[1])},
#  qw("" stringify);

#sub stringify {
#   $_[0];
#}


sub kids {
    my $self = shift;
    if (@_) {
        @$self = $self->[0], map {Node($_)} @_;
    }
    my ($name, $kids) = @$self;
    if (!ref($kids)) {
        return $kids;
    }
    return map {Node(@$_)} @$kids;
}
*k = \&kids;
*children = \&kids;
*getChildren = \&kids;
*getKids = \&kids;

sub subnodes {
    my $self = shift;
    return grep {ref($_)} $self->kids;
}
*ntnodes = \&subnodes;

sub element {
    my $self = shift;
    if (@_) {
        $self->[0] = shift;
    }
    return $self->[0];
}
*e = \&element;
*name = \&element;
*tagname = \&element;

sub data {
    my $self = shift;
    if (@_) {
        $self->[1] = shift;
    }
    return $self->[1];
}


sub AUTOLOAD {
    my $self = shift;
    my @args = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    if ($name eq "DESTROY") {
	# we dont want to propagate this!!
	return;
    }

    if ($name =~ /^([a-zA-Z]+)_(\w+)/) {
        if ($self->can($1)) {
            return $self->$1($2, @args);
        }
    }
    confess("no such method:$name)");
}

# --MISC--

sub splitpath {
    my $node = shift;
    return ref($node) ? (@$node) : (split(/\//, $node));
}

sub test_eq {
    my ($ev, $node) = @_;
    return $ev eq $node || $node eq '*';
}

1;

