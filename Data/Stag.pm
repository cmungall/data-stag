# $Id: Stag.pm,v 1.20 2003/08/02 20:10:06 cmungall Exp $
# -------------------------------------------------------
#
# Copyright (C) 2002 Chris Mungall <cjm@fruitfly.org>
#
# See also - http://stag.sourceforge.net
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

#---
# POD docs at end of file
#---

package Data::Stag;

require 5.6.0;
use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $DEBUG $AUTOLOAD @AUTOMETHODS @OLD);
use Carp;
use Data::Stag::Base;
use XML::Parser::PerlSAX;

use vars qw($VERSION);
$VERSION="0.03";

@AUTOMETHODS = qw(
                  new
                  node
                  nodify stagify
                  unflatten
                  from
                  fn findnode
                  fvl findvallist
                  fv findval
                  fvl findvallist
                  sfv sfindval
                  g  get
                  sg sget scalarget
                  gl getl getlist
                  gn getn getnode
                  s  set
                  u  unset
		  free
                  a  add
                  e element name
                  k kids children
                  ak addkid addchild
                  subnodes
                  isterminal
                  j nj njoin
                  paste
                  qm qmatch
                  tm tmatch
                  tmh tmatchhash
                  tmn tmatchnode
                  cm cmatch
                  w where
		  iterate
                  run
                  collapse
                  merge
                  d duplicate
                  isanode
                  parser
                  parse parsefile
		  parsestr
		  generate gen write
                  makehandler mh
                  findhandler 
                  getformathandler 
		  chainhandlers
                  xml   tree2xml
                  hash tree2hash
                  pairs tree2pairs
                  sax tree2sax
                  xp xpath tree2xpath
                  xpq xpquery xpathquery
                 );

@OLD = 
  qw(
     findSubTree
     findSubTreeVal
     findSubTreeValList
     findSubTreeMatch
     setSubTreeVal
     );

@EXPORT_OK =
  ((
    map {
        "stag_$_"
    } @AUTOMETHODS
   ),
   @OLD,
   qw(
      Node
      xml2tree
      tree2xml
      stag_unflatten
      stag_nodify
      stag_load
      stag_loadxml
     )
  );
%EXPORT_TAGS = (all => [@EXPORT_OK],
                lazy => [@EXPORT_OK,
                         @AUTOMETHODS]);
@ISA = qw(Exporter);

our $DEBUG;
our $IMPL = "Data::Stag::StagImpl";
use Data::Stag::StagImpl;

sub DEBUG {
    $DEBUG = shift if @_;
    return $DEBUG;
}

sub IMPL {
    $IMPL = shift if @_;
    return $IMPL;
}

# OO usage
sub new {
    shift;
    return $IMPL->new(@_);
}
# procedural usage
sub stag_new {
    return $IMPL->new(@_);
}
*Node = \&stag_new;
*node = \&stag_new;

sub stag_from {
    return $IMPL->from(@_);
}

sub stag_load {
    my $node = stag_new();
    return $node->parse(@_);
}

sub stag_loadxml {
    return $IMPL->from('xml', @_);
}

sub stag_nodify {
    bless shift, $IMPL;
}

# allows entering trees like this
# [tag=>val, tag=>val, tag=>val]
sub stag_unflatten {
    return $IMPL->unflatten(@_);
}

sub xml2tree {
    warn("DEPRECATED: xml2tree");
    stag_from('xml', @_);
}
sub tree2xml {
    warn("DEPRECATED: tree2xml");
    stag_xml(@_);
}

no strict 'refs';
sub AUTOLOAD {
    my @args = @_;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    $name =~ s/^stag//;
    $name =~ s/_//g;

    if (grep {lc($name) eq lc($_)} @OLD) {
        warn "DEPRECATED: $name";
    }

    # make it all lower case
    unless (UNIVERSAL::can($IMPL, $name)) {
        $name = lc($name);
    }
    my $meth = $IMPL.'::'.$name;
    
    &$meth(@args);
}

1;

__END__

=head1 NAME

  Data::Stag - Structured Tags datastructures

=head1 SYNOPSIS

  # PROCEDURAL USAGE
  use Data::Stag qw(:all);
  $doc = stag_parse($file);
  @persons = stag_find($doc, "person");
  foreach $p (@persons) {
    printf "%s, %s phone: %s\n",
      stag_sget($p, "family_name"),
      stag_sget($p, "given_name"),
      stag_sget($p, "phone_no"),
    ;
  } 

  # OO USAGE
  use Data::Stag;
  $doc = Data::Stag->new->parse($file);
  @persons = $doc->find("person");
  foreach $p (@person) {
    printf "%s, %s phone:%s\n",
      $p->sget("family_name"),
      $p->sget("given_name"),
      $p->sget("phone_no"),
    ;
  }

=cut

=head1 DESCRIPTION

This module is for manipulating data as recursively nested tag/value
pairs (Structured TAGs or Simple Tree AGgreggates). These
datastructures can be represented as nested arrays, which have the
advantage of being native to perl. A simple example is shown below:

  [ person=> [  [ family_name => $family_name ],
                [ given_name  => $given_name  ],
                [ phone_no    => $phone_no    ] ] ],

L<Data::Stag> uses a subset of XML for import and export. This
means the module can also be used as a general XML parser/writer (with
certain caveats).

The above set of structured tags can be represented in XML as
  
  <person>
    <family_name>...</family_name>
    <given_name>...</given_name>
    <phone_no>...</phone_no>
  </person>

Querying is performed by passing functions, for example:

  # get all people in dataset with name starting 'A'
  @persons = 
    $document->where('person',
                     sub {shift->sget('family_name') =~ /^A/});

One of the things that marks this module out against other XML modules
is this emphasis on a functional approach as opposed to an OO
approach (it may appeal to Lisp programmers).

=head2 PROCEDURAL VS OBJECT ORIENTED USAGE

Depending on your preference, this module can be used a set of
procedural subroutine calls, or as method calls upon Data::Stag
objects, or both.

In procedural mode, all the subroutine calls are prefixed "stag_" to
avoid namespace clashes. The following two calls are equivalent:

  stag_findnode($doc, "person");
  $doc->findnode("person");

In object mode, you can treat any tree element as if it is an object
with automatically defined methods for getting/setting the tag values.

=head2 USE OF XML

Nested arrays can be imported and exported as XML, as well as other
formats. XML can be slurped into memory all at once (using less memory
than an equivalent DOM tree), or a simplified SAX style event handling
model can be used. Similarly, data can be exported all at once, or as
a series of events.

Although this module can be used as a general XML tool, it is intended
primarily as a tool for manipulating complex data using nested
tag/value pairs.

By using a simpler subset of XML that can be treated as equivalent to
a basic data tree structure, we can write simpler, cleaner code. This
simplicity comes at a price - this module is not very suitable for XML
with attributes or mixed content.

All attributes are turned into elements. This means that it will not
round-trip a piece of xml with attributes in it. For some applications
this is acceptable, for others it is not.

Mixed content cannot be represented in a simple tree format, so this
is also expanded.

The following piece of XML

  <paragraph id="1">
    example of <bold>mixed</bold>content
  </paragraph>

gets parsed as if it were actually:

  <paragraph>
    <paragraph-id>1</paragraph-id>
    <paragraph-text>example of</paragraph-text>
    <bold>mixed</bold>
    <paragraph-text>content</paragraph-text>
  </paragraph>

This module is more suited to dealing with complex datamodels than
dealing with marked up text

It can also be used as part of a SAX-style event generation / handling
framework - see L<Data::Stag::Base>

Because nested arrays are native to perl, we can specify an XML
datastructure directly in perl without going through multiple object
calls.

For example, instead of the lengthy

  $obj->startTag("record");
  $obj->startTag("field1");
  $obj->characters("foo");
  $obj->endTag("field1");
  $obj->startTag("field2");
  $obj->characters("bar");
  $obj->endTag("field2");
  $obj->end("record");

We can instead write

  $struct = [ record => [
              [ field1 => 'foo'],
              [ field2 => 'bar']]];

If this appeals to you, then maybe this module is for you.

=head2 PARSING

parsing out subsections of a tree and changing sub-elements

  use Data::Stag qw(:all);
  my $tree = stag_parse($xmlfile);
  my ($subtree) = stag_findnode($tree, $element);
  stag_set($element, $sub_element, $new_val);
  print stag_xml($subtree);

=head2 OBJECT ORIENTED

the same can be done in a more OO fashion

  use Data::Stag qw(:all);
  my $tree = Data::Stag->parse($xmlfile);
  my ($subtree) = $tree->findnode($element);
  $element->set($sub_element, $new_val);
  print $subtree->xml;

=head2 IN A STREAM

  use Data::Stag;
  # catch the end of 'person' elements
  my $h = Data::Stag->makehandler( person=> sub {
                                               my ($self, $person) = @_;
                                               printf "name:%s phone:%s\n",
                                                 $person->get_name,
                                                 $person->get_phone;
                                                });
  Data::Stag->parse(-handler=>$h,
                    -file=>$f);

see L<Data::Stag::BaseHandler> for writing handlers

See the Stag website at L<http://stag.sourceforge.net> for more examples.

=head2 STRUCTURED TAGS TREE DATA STRUCTURE

A tree of structured tags is represented as a recursively nested
array, the elements of the array represent nodes in the tree.

A node is a name/data pair, that can represent tags and values.  A
node is represented using a reference to an array, where the first
element of the array is the B<tagname>, or B<element>, and the second
element is the B<data>

This can be visualised as a box:

  +-----------+
  |Name | Data|
  +-----------+

In perl, we represent this pair as a reference to an array

  [ Name => $Data ]

The B<Data> can either be a list of child nodes (subtrees), or a data value.

The terminal nodes (leafs of the tree) contain data values; this is represented in perl
using primitive scalars.

For example:

  [ Name => 'Fred' ]

For non-terminal nodes, the Data is a reference to an array, where
each element of the the array is a new node.

  +-----------+
  |Name | Data|
  +-----------+
          |||   +-----------+
          ||+-->|Name | Data|
          ||    +-----------+
          ||    
          ||    +-----------+
          |+--->|Name | Data|
          |     +-----------+
          |     
          |     +-----------+
          +---->|Name | Data|
                +-----------+

In perl this would be:

  [ Name => [
              [Name1 => $Data1],
              [Name2 => $Data2],
              [Name3 => $Data3],
            ]
  ];

The extra level of nesting is required to be able to store any node in
the tree using a single variable. This representation has lots of
advantages over others, eg hashes and mixed hash/array structures.

=head2 MANIPULATION AND QUERYING

The following example is taken from molecular biology; we have a list
of species (mouse, human, fly) and a list of genes found in that
species. These are cross-referenced by an identifier called
B<tax_id>. We can do a relational-style natural join on this
identifier, as follows -

  use Data::Stag qw(:all);
  my $tree =
  Data::Stag->new(
    'db' => [
    [ 'species_set' => [
      [ 'species' => [
        [ 'common_name' => 'house mouse' ],
        [ 'binomial' => 'Mus musculus' ],
        [ 'tax_id' => '10090' ]]],
      [ 'species' => [
        [ 'common_name' => 'fruit fly' ],
        [ 'binomial' => 'Drosophila melanogaster' ],
        [ 'tax_id' => '7227' ]]],
      [ 'species' => [
        [ 'common_name' => 'human' ],
        [ 'binomial' => 'Homo sapiens' ],
        [ 'tax_id' => '9606' ]]]]],
    [ 'gene_set' => [
      [ 'gene' => [
        [ 'symbol' => 'HGNC' ],
        [ 'tax_id' => '9606' ],
        [ 'phenotype' => 'Hemochromatosis' ],
        [ 'phenotype' => 'Porphyria variegata' ],
        [ 'GO_term' => 'iron homeostasis' ],
        [ 'map' => '6p21.3' ]]],
      [ 'gene' => [
        [ 'symbol' => 'Hfe' ],
        [ 'synonym' => 'MR2' ],
        [ 'tax_id' => '10090' ],
        [ 'GO_term' => 'integral membrane protein' ],
        [ 'map' => '13 A2-A4' ]]]]]]
   );

  # natural join of species and gene parts of tree,
  # based on 'tax_id' element
  my ($gene_set) = $tree->findnode("gene_set");
  my ($species_set) = $tree->findnode("species_set");
  $gene_set->njoin("gene", "tax_id", $species_set);
  print $gene_set->xml;

  # find all genes starting with H in human
  my @genes =
    $gene_set->where('gene',
                     sub { my $g = shift;
                           $g->get_symbol =~ /^H/ &&
                           $g->findval("common_name") eq ('human')});

=head2 S-Expression (Lisp) representation

The data represented using this module can be represented as
Lisp-style S-Expressions.

See L<Data::Stag::SxprParser> and  L<Data::Stag::SxprWriter>

If we execute this line

  print $tree->sxpr;

The following S-Expression will be printed:

  '(db
    (species_set
      (species
        (common_name "house mouse")
        (binomial "Mus musculus")
        (tax_id "10090"))
      (species
        (common_name "fruit fly")
        (binomial "Drosophila melanogaster")
        (tax_id "7227"))
      (species
        (common_name "human")
        (binomial "Homo sapiens")
        (tax_id "9606")))
    (gene_set
      (gene
        (symbol "HGNC")
        (tax_id "9606")
        (phenotype "Hemochromatosis")
        (phenotype "Porphyria variegata")
        (GO_term "iron homeostasis")
        (map
          (cytological
            (chromosome "6")
            (band "p21.3"))))
      (gene
        (symbol "Hfe")
        (synonym "MR2")
        (tax_id "10090")
        (GO_term "integral membrane protein")))
    (similarity_set
      (pair
        (symbol "HGNC")
        (symbol "Hfe"))
      (pair
        (symbol "WNT3A")
        (symbol "Wnt3a"))))

=head3 TIPS FOR EMACS USERS AND LISP PROGRAMMERS

If you use emacs, you can save this as a file with the ".el" suffix
and get syntax highlighting for editing this file. Quotes around the
terminal node data items are optional.


If you know emacs lisp or any other lisp, this also turns out to be a
very nice language for manipulating these datastructures. Try copying
and pasting the above s-expression to the emacs scratch buffer and
playing with it!

I think this module turns out to be a very nice way using my two
favourite lnaguages, lisp and perl together.

=cut

#'

=head2 INDENTED TEXT REPRESENTATION

Data::Stag has its own text format for writing data trees. Again,
this is only possible because we are working with a subset of XML (no
attributes, no mixed elements). The data structure above can be
written as follows -

  db:
    species_set:
      species:
        common_name: house mouse
        binomial: Mus musculus
        tax_id: 10090
      species:
        common_name: fruit fly
        binomial: Drosophila melanogaster
        tax_id: 7227
      species:
        common_name: human
        binomial: Homo sapiens
        tax_id: 9606
    gene_set:
      gene:
        symbol: HGNC
        tax_id: 9606
        phenotype: Hemochromatosis
        phenotype: Porphyria variegata
        GO_term: iron homeostasis
        map: 6p21.3
      gene:
        symbol: Hfe
        synonym: MR2
        tax_id: 10090
        GO_term: integral membrane protein
        map: 13 A2-A4
    similarity_set:
      pair:
        symbol: HGNC
        symbol: Hfe
      pair:
        symbol: WNT3A
        symbol: Wnt3a

See L<Data::Stag::ITextParser> and  L<Data::Stag::ITextWriter>


=head2 NESTED ARRAY SPECIFICATION II

To avoid excessive square bracket usage, you can specify a structure
like this:


  use Data::Stag qw(:all);
  
  *N = \&stag_new;
  my $tree =
    N(top=>[
            N('personset'=>[
                            N('person'=>[
                                         N('name'=>'davey'),
                                         N('address'=>'here'),
                                         N('description'=>[
                                                           N('hair'=>'green'),
                                                           N('eyes'=>'two'),
                                                           N('teeth'=>5),
                                                          ]
                                          ),
                                         N('pets'=>[
                                                    N('petname'=>'igor'),
                                                    N('petname'=>'ginger'),
                                                   ]
                                          ),
                                                                          
                                        ],
                             ),
                            N('person'=>[
                                         N('name'=>'shuggy'),
                                         N('address'=>'there'),
                                         N('description'=>[
                                                           N('hair'=>'red'),
                                                           N('eyes'=>'three'),
                                                           N('teeth'=>1),
                                                          ]
                                          ),
                                         N('pets'=>[
                                                    N('petname'=>'thud'),
                                                    N('petname'=>'spud'),
                                                   ]
                                          ),
                                        ]
                             ),
                           ]
             ),
            N('animalset'=>[
                            N('animal'=>[
                                         N('name'=>'igor'),
                                         N('class'=>'rat'),
                                         N('description'=>[
                                                           N('fur'=>'white'),
                                                           N('eyes'=>'red'),
                                                           N('teeth'=>50),
                                                          ],
                                          ),
                                        ],
                             ),
                           ]
             ),

           ]
     );

  # find all people
  my @persons = stag_find($tree, 'person');

  # write xml for all red haired people
  foreach my $p (@persons) {
    print stag_xml($p)
      if stag_tmatch($p, "hair", "red");
  } ;

  # find all people that have name == shuggy
  my @p =
    stag_qmatch($tree, 
                "person",
                "name",
                "shuggy");

=head1 NODES AS DATA OBJECTS

As well as the methods listed below, a node can be treated as if it is
a data object of a class determined by the element.

For example, the following are equivalent.

  $node->get_name;
  $node->get('name');

  $node->set_name('fred');
  $node->set('name', 'fred');

This is really just syntactic sugar. The autoloaded methods are not
checked against any schema, although this may be added in future.

One addition slated for a future release is the ability to give
particular elements certain behaviour, and allow inheritance and all
that kind of thing.

  fullname: $obj->given_name . ' ' . $obj->family_name;

Although it is the module authors preference to avoid this kind of OO
paradigm, and instead enforce a cleaner seperation of code from data,
utilising a more functional style of programming.

=head1 METHODS

All method calls are also available as procedural subroutine calls;
unless otherwise noted, the subroutine call is the same as the method
call, but with the string B<stag_> prefixed to the method name. The
first argument should be a Data::Stag datastructure.

To import all subroutines into the current namespace, use this idiom:

  use Data::Stag qw(:all);

If you wish to use this module procedurally, and you are too lazy to
prefix all calls with B<stag_>, use this idiom:

  use Data::Stag qw(:lazy);

=head3 MNEMONICS

Most method calls also have a handy short mnemonic. Use of these is
optional. Software engineering types prefer longer names, in the
belief that this leads to clearer code. Hacker types prefer shorter
names, as this requires less keystrokes, and leads to a more compact
representation of the code. It is expected that if you do use this
module, then its usage will be fairly ubiquitous within your code, and
the mnemonics will become familiar, much like the qw and s/ operators
in perl. As always with perl, the decision is yours.


  

=head2 INITIALIZATION METHODS



=head3 new 

       Title: new

        Args: element str, data ANY
     Returns: Data::Stag node
     Example: $node = stag_new();
     Example: $node = Data::Stag->new;
     Example: $node = Data::Stag->new(person => [[name=>$n], [phone=>$p]]);

creates a new instance of a Data::Stag node


=head3 stagify (nodify)

       Title: stagify
     Synonym: nodify
        Args: data array-reference
     Returns: Data::Stag node
     Example: $node = stag_stagify([person => [[name=>$n], [phone=>$p]]]);

turns a perl array reference into a Data::Stag node.

similar to B<new>


=head3 parse 

       Title: parse

        Args: [file str], [format str], [handler obj], [fh FileHandle]
     Returns: Data::Stag node
     Example: $node = stag_parse($fn);
     Example: $node = Data::Stag->parse(-file=>$fn, -handler=>$myhandler);

slurps a file or string into a Data::Stag node structure. Will
guess the format from the suffix if it is not given.

The format can also be the name of a parsing module, or an actual
parser object

The handler is any object that can take nested Stag events
(start_event, end_event, evbody) which are generated from the
parse. If the handler is omitted, all events will be cached and the
resulting tree will be returned.

=head3 parsestr 

       Title: parsestr

        Args: [str str], [format str], [handler obj]
     Returns: Data::Stag node
     Example: $node = stag_parsestr('(a (b (c "1")))');
     Example: $node = Data::Stag->parsestr(-str=>$fn, -handler=>$myhandler);

Similar to parse(), except the first argument is a string

=head3 from 

       Title: from

        Args: format str, source str
     Returns: Data::Stag node
     Example: $node = stag_from('xml', $fn);
     Example: $node = stag_from('xmlstr', q[<top><x>1</x></top>]);
     Example: $node = Data::Stag->from($parser, $fn);

Similar to B<parse>

slurps a file or string into a Data::Stag node structure.

The format can also be the name of a parsing module, or an actual
parser object



=head3 unflatten 

       Title: unflatten

        Args: data array
     Returns: Data::Stag node
     Example: $node = stag_unflatten(person=>[name=>$n, phone=>$p, address=>[street=>$s, city=>$c]]);

Creates a node structure from a semi-flattened representation, in
which children of a node are represented as a flat list of data rather
than a list of array references.

This means a structure can be specified as:

  person=>[name=>$n,
           phone=>$p, 
           address=>[street=>$s, 
                     city=>$c]]

Instead of:

  [person=>[ [name=>$n],
             [phone=>$p], 
             [address=>[ [street=>$s], 
                         [city=>$c] ] ]
           ]
  ]

The former gets converted into the latter for the internal representation


=head3 makehandler

       Title: makehandler

        Args: hash of CODEREFs keyed by element name
     Returns: L<Data::Stag::BaseHandler>
     Example: $h = Data::Stag->makehandler(%subs);

This creates a Stag event handler

  $h = Data::Stag->makehandler(
                               a => sub { my ($self,$stag) = @_;
                                          $stag->set_foo("bar");});
  $stag = Data::Stag->parse(-str=>"(...)", -handler=>$h)

  
=head3 getformathandler

       Title: getformathandler

        Args: format str OR L<Data::Stag::BaseHandler>
     Returns: L<Data::Stag::BaseHandler>
     Example: $h = Data::Stag->getformathandler('xml');

Creates a Stag event handler - this handler can be passed to an event
generator / parser. Built in handlers include:

=over

=item xml

Generates xml tags from events

=item sxpr

Generates S-Expressions from events

=item itext

Generates indented text from events

=back

=head3 chainhandler

       Title: chainhandler

        Args: blocked events - str or str[]
              initial handler - handler object
              final handler - handler object
     Returns: 
     Example: $h = Data::Stag->chainhandler('foo', $processor, 'xml')

  $processor = Data::Stag->makehandler(
				       a => sub { my ($self,$stag) = @_;
						  $stag->set_foo("bar");});
  $chainh = Data::Stag->chainhandler(['a', 'b'], $processor, 'xml');
  $stag = Data::Stag->parse(-str=>"(...)", -handler=>$chainh)

chains together two handlers (see stag-handle.pl)


=head2  RECURSIVE SEARCHING


=head3 find (f)

       Title: find
     Synonym: f

        Args: element str
     Returns: node[] or ANY
     Example: @persons = stag_find($struct, 'person');
     Example: @persons = $struct->find('person');

recursively searches tree for all elements of the given type, and
returns all nodes or data elements found.

if the element found is a non-terminal node, will return the node
if the element found is a terminal (leaf) node, will return the data value

the element argument can be a path

  @names = $struct->find('department/person/name');

will find name in the nested structure below:

  (department
   (person
    (name "foo")))


=head3 findnode (fn)

       Title: findnode
     Synonym: fn

        Args: element str
     Returns: node[]
     Example: @persons = stag_findnode($struct, 'person');
     Example: @persons = $struct->findnode('person');

recursively searches tree for all elements of the given type, and
returns all nodes found.

paths can also be used (see B<find>)

=head3 findval (fv)

       Title: findval
     Synonym: fv

        Args: element str
     Returns: ANY[] or ANY
     Example: @names = stag_findval($struct, 'name');
     Example: @names = $struct->findval('name');
     Example: $firstname = $struct->findval('name');

recursively searches tree for all elements of the given type, and
returns all data values found. the data values could be primitive
scalars or nodes.

paths can also be used (see B<find>)

=head3 sfindval (sfv)

       Title: sfindval
     Synonym: sfv

        Args: element str
     Returns: ANY
     Example: $name = stag_sfindval($struct, 'name');
     Example: $name = $struct->sfindval('name');

as findval, but returns the first value found

paths can also be used (see B<find>)

=head3 findvallist (fvl)

       Title: findvallist
     Synonym: fvl

        Args: element str[]
     Returns: ANY[]
     Example: ($name, $phone) = stag_findvallist($personstruct, 'name', 'phone');
     Example: ($name, $phone) = $personstruct->findvallist('name', 'phone');

recursively searches tree for all elements in the list

DEPRECATED


=head2 DATA ACCESSOR METHODS


these allow getting and setting of elements directly underneath the
current one



=head3 get (g)

       Title: get
     Synonym: g

        Args: element str
      Return: node[] or ANY
     Example: $name = $person->get('name');
     Example: @phone_nos = $person->get('phone_no');

gets the value of the named sub-element

if the sub-element is a non-terminal, will return a node(s)
if the sub-element is a terminal (leaf) it will return the data value(s)

the examples above would work on a data structure like this:

  [person => [ [name => 'fred'],
               [phone_no => '1-800-111-2222'],
               [phone_no => '1-415-555-5555']]]

will return an array or single value depending on the context

[equivalent to findval(), except that only direct children (as
opposed to all descendents) are checked]

paths can also be used, like this:

 @phones_nos = $struct->get('person/phone_no')

=head3 sget (sg)

       Title: sget
     Synonym: sg

        Args: element str
      Return: ANY
     Example: $name = $person->sget('name');
     Example: $phone = $person->sget('phone_no');
     Example: $phone = $person->sget('department/person/name');

as B<get> but always returns a single value

[equivalent to sfindval(), except that only direct children (as
opposed to all descendents) are checked]


=head3 getl (gl getlist)

       Title: gl
     Synonym: getl
     Synonym: getlist

        Args: element str[]
      Return: node[] or ANY[]
     Example: ($name, @phone) = $person->getl('name', 'phone_no');

returns the data values for a list of sub-elements of a node

[equivalent to findvallist(), except that only direct children (as
opposed to all descendents) are checked]


=head3 getn (gn getnode)

       Title: getn
     Synonym: gn
     Synonym: getnode

        Args: element str
      Return: node[]
     Example: $namestruct = $person->getn('name');
     Example: @pstructs = $person->getn('phone_no');

as B<get> but returns the whole node rather than just the data valie

[equivalent to findnode(), except that only direct children (as
opposed to all descendents) are checked]


=head3 set (s)

       Title: set
     Synonym: s

        Args: element str, datavalue ANY (list)
      Return: ANY
     Example: $person->set('name', 'fred');    # single val
     Example: $person->set('phone_no', $cellphone, $homephone);

sets the data value of an element for any node. if the element is
multivalued, all the old values will be replaced with the new ones
specified.

ordering will be preserved, unless the element specified does not
exist, in which case, the new tag/value pair will be placed at the
end.

for example, if we have a stag node $person

  person:
    name: shuggy
    job:  bus driver

if we do this

  $person->set('name', ());

we will end up with

  person:
    job:  bus driver

then if we do this

  $person->set('name', 'shuggy');

the 'name' node will be placed as the last attribute

  person:
    job:  bus driver
    name: shuggy

You can also use B<magic methods>, for example

  $person->set_name('shuggy');
  $person->set_job('bus driver', 'poet');
  print $person->itext;

will print

  person:
    name: shuggy
    job:  bus driver
    job:  poet

  
note that if the datavalue is a non-terminal node as opposed to a
primitive value, then you have to do it like this:

  $people  = Data::Stag->new(people=>[
                                      [person=>[[name=>'Sherlock Holmes']]],
                                      [person=>[[name=>'Moriarty']]],
                                     ]);
  $address = Data::Stag->new(address=>[
                                       [address_line=>"221B Baker Street"],
                                       [city=>"London"],
                                       [country=>"Great Britain"]]);
  ($person) = $people->qmatch('person', (name => "Sherlock Holmes"));
  $person->set("address", $address->data);

=head3 unset (u)

       Title: unset
     Synonym: u

        Args: element str, datavalue ANY
      Return: ANY
     Example: $person->unset('name');
     Example: $person->unset('phone_no');

prunes all nodes of the specified element from the current node

You can use B<magic methods>, like this

  $person->unset_name;
  $person->unset_phone_no;

=head3 free 

       Title: free
     Synonym: u

        Args: 
      Return: 
     Example: $person->free;

removes all data from a node. If that node is a subnode of another
node, it is removed altogether

for instance, if we had the data below:

  <person>
    <name>fred</name>
    <address>
    ..
    </address>
  </person>

and called

  $person->get_address->free

then the person node would look like this:

  <person>
    <name>fred</name>
  </person>

=head3 add (a)

       Title: add
     Synonym: a

        Args: element str, datavalue ANY[]
      Return: ANY
     Example: $person->add('phone_no', $cellphone, $homephone);

adds a datavalue or list of datavalues. appends if already existing,
creates new element value pairs if not already existing.



=head3 element (e name)

       Title: element
     Synonym: e
     Synonym: name

        Args:
      Return: element str
     Example: $element = $struct->element

returns the B<element name> of the current node.

This is illustrated in the different representation formats below

=over

=item sxpr

  (element "data")

or

  (element
   (sub_element "..."))

=item xml

  <element>data</element>

or

  <element>
    <sub_element>...</sub_element>
  </element>

=item perl

  [element => $data ]

or

  [element => [
                [sub_element => "..." ]]]

=item itext

  element: data

or

  element:
    sub_element: ...

=back
 

=head3 kids (k children)

       Title: kids
     Synonym: k
     Synonym: children

        Args:
      Return: ANY or ANY[]
     Example: @nodes = $person->kids
     Example: $name = $namestruct->kids

returns the data value(s) of the current node; if it is a terminal
node, returns a single value which is the data. if it is non-terminal,
returns an array of nodes



=head3 addkid (ak addchild)

       Title: addkid
     Synonym: ak
     Synonym: addchild

        Args: kid node
      Return: ANY
     Example: $person->addkid('job', $job);

adds a new child node to a non-terminal node, after all the existing child nodes

=head3 subnodes

       Title: subnodes

        Args: 
      Return: ANY[]
     Example: @nodes = $person->subnodes

returns the non-terminal data value(s) of the current node;

  

=head2 QUERYING AND ADVANCED DATA MANIPULATION




=head3 njoin (j)

       Title: njoin
     Synonym: j
     Synonym: nj

        Args: element str, key str, data Node
      Return: undef

does a relational style natural join - see previous example in this doc



=head3 qmatch (qm)

       Title: qmatch
     Synonym: qm

        Args: return-element str, match-element str, match-value str
      Return: node[]
     Example: @persons = $s->qmatch('person', 'name', 'fred');
     Example: @persons = $s->qmatch('person', (job=>'bus driver'));

queries the node tree for all elements that satisfy the specified
key=val match - see previous example in this doc

for those inclined to thinking relationally, this can be thought of
as a query that returns a stag object:

  SELECT <return-element> FROM <stag-node> WHERE <match-element> = <match-value>

this always returns an array; this means that calling in a scalar
context will return the number of elements; for example

  $n = $s->qmatch('person', (name=>'fred'));

the value of $n will be equal to the number of persons called fred

=head3 tmatch (tm)

       Title: tmatch
     Synonym: tm

        Args: element str, value str
      Return: bool
     Example: @persons = grep {$_->tmatch('name', 'fred')} @persons

returns true if the the value of the specified element matches - see
previous example in this doc



=head3 tmatchhash (tmh)

       Title: tmatchhash
     Synonym: tmh

        Args: match hashref
      Return: bool
     Example: @persons = grep {$_->tmatchhash({name=>'fred', hair_colour=>'green'})} @persons

returns true if the node matches a set of constraints, specified as
hash.



=head3 tmatchnode (tmn)

       Title: tmatchnode
     Synonym: tmn

        Args: match node
      Return: bool
     Example: @persons = grep {$_->tmatchnode([person=>[[name=>'fred'], [hair_colour=>'green']]])} @persons

returns true if the node matches a set of constraints, specified as node



=head3 cmatch (cm)

       Title: cmatch
     Synonym: cm

        Args: element str, value str
      Return: bool
     Example: $n_freds = $personset->cmatch('name', 'fred');

counts the number of matches



=head3 where (w)

       Title: where
     Synonym: w

        Args: element str, test CODE
      Return: Node[]
     Example: @rich_persons = $data->where('person', sub {shift->get_salary > 100000});

the tree is queried for all elements of the specified type that
satisfy the coderef (must return a boolean)

  my @rich_dog_or_cat_owners =
    $data->where('person',
                 sub {my $p = shift;
                      $p->get_salary > 100000 &&
                      $p->where('pet',
                                sub {shift->get_type =~ /(dog|cat)/})});





=head3 iterate (i)

       Title: iterate
     Synonym: i

        Args: CODE
      Return: Node[]
     Example: $data->iterate(sub {
				 my $stag = shift;
				 my $parent = shift;
				 if ($stag->element eq 'pet') {
				     $parent->set_pet_name($stag->get_name);
				 }
			     });

iterates through whole tree calling the specified subroutine.

the first arg passed to the subroutine is the stag node representing
the tree at that point; the second arg is for the parent.

for instance, the example code above would turn this

  (person
   (name "jim")
   (pet
    (name "fluffy")))

into this

  (person
   (name "jim")
   (pet_name "fluffy")
   (pet
    (name "fluffy")))

=head2 MISCELLANEOUS METHODS



=head3 duplicate (d)

       Title: duplicate
     Synonym: d

        Args:
      Return: Node
     Example: $node2 = $node->duplicate;

does a deep copy of a stag structure

=head3 isanode

       Title: isanode

        Args:
      Return: bool
     Example: if (stag_isanode($node)) { ... }



=head3 hash

       Title: hash

        Args:
      Return: hash
     Example: $h = $node->hash;

turns a tree into a hash. all data values will be arrayrefs



=head3 pairs

       Title: pairs

turns a tree into a hash. all data values will be scalar (IMPORTANT:
this means duplicate values will be lost)




=head3 write

       Title: write

        Args: filename str, format str[optional]
      Return:
     Example: $node->write("myfile.xml");
     Example: $node->write("myfile", "itext");

will try and guess the format from the extension if not specified



=head3 xml

       Title: xml

        Args: filename str, format str[optional]
      Return:
     Example: $node->write("myfile.xml");
     Example: $node->write("myfile", "itext");


        Args:
      Return: xml str
     Example: print $node->xml;



=head2 XML METHODS



=head3 sax

       Title: sax

        Args: saxhandler SAX-CLASS
      Return:
     Example: $node->sax($mysaxhandler);

turns a tree into a series of SAX events



=head3 xpath (xp tree2xpath)

       Title: xpath
     Synonym: xp
     Synonym: tree2xpath

        Args:
      Return: xpath object
     Example: $xp = $node->xpath; $q = $xp->find($xpathquerystr);



=head3 xpquery (xpq xpathquery)

       Title: xpquery
     Synonym: xpq
     Synonym: xpathquery

        Args: xpathquery str
      Return: Node[]
     Example: @nodes = $node->xqp($xpathquerystr);

=head1 BUGS

none known so far, possibly quite a few undocumented features!

Not a bug, but the underlying default datastructure of nested arrays
is more heavyweight than it needs to be. More lightweight
implementations are possible. Some time I will write a C
implementation.

=head1 WEBSITE

L<http://stag.sourceforge.net>

=head1 WEBSITE

http://stag.sourceforge.net

=head1 AUTHOR

Chris Mungall <F<cjm@fruitfly.org>>

=head1 COPYRIGHT

Copyright (c) 2002 Chris Mungall

This module is free software.
You may distribute this module under the same terms as perl itself

=cut



1;

