use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 7;
}
use XML::NestArray qw(:all);
use XML::NestArray::Arr2HTML;
use XML::NestArray::null;
use XML::Handler::XMLWriter;
use FileHandle;
use strict;
use Data::Dumper;

my $tree =
  [top => [
           [
            personset => [
                         [person => [
                                     [ name => 'shuggy' ],
                                     [ job => 'bus driver' ],
                                     [ age => '55' ],
                                    ],
                         ],
                         [person => [
                                     [ name => 'tam' ],
                                     [ job  => 'forklift driver' ],
                                     [ favourite_food => 'chips' ],
                                    ],
                         ],
                         ],
           ],
          ],
  ];

my ($fh, $handler, $writer);
$fh = FileHandle->new(">t/z.xml");
$writer = XML::Handler::XMLWriter->new(Output=>$fh);
#my $writer = XML::Handler::XMLWriter->new();
narr_sax($tree, $writer);

$fh = FileHandle->new(">qq");
$writer = XML::Handler::XMLWriter->new();
#my $handler = XML::NestArray::Base->new(Handler=>$writer2);
#my $handler = XML::NestArray::Base->new(Handler=>$writer);
#print Dumper [narr_findnode($tree, "personset")];
my @p = narr_findnode($tree, "person");
map {narr_sax($_, $writer)} @p;
ok(@p==2);
#print Dumper $handler;
#die;

#my $null = XML::NestArray::null->new();
#my $html = XML::NestArray::Arr2HTML->new(Handler=>$null);
#$handler = XML::NestArray::SAX2NestArray->new(Handler=>$html);
#tree2sax($tree, $handler);
#

my $na = narr_from("xml", "t/z.xml");
my $h = narr_hash($na);
print Dumper $h;
print narr_xml($tree);

# test replacement
narr_findnode($tree, "age", [age_months=>100]);
print narr_xml($tree);
print "checking..\n";
@p = grep {narr_findval($_, "name") eq ("shuggy") } narr_findnode($tree, "person");
map {print narr_xml($_)} @p;
ok((narr_findval($p[0], "age_months")) == (100));

my @names = narr_findval($tree, "person/name");
ok("@names" eq "shuggy tam");

@p =
  narr_where($tree, 
             "person",
             sub {narr_tmatch(shift, "job", "forklift driver")});
print narr_xml(@p);
ok(narr_tmatch($p[0], "name", "tam"));
ok(narr_tmatch($p[0], "job", "forklift driver"));
ok(!narr_tmatch($p[0], "name", "jim"));

# replace bus driver with new node
narr_where($tree, 
           "person",
           sub {
               narr_tmatch(shift, "job", 'bus driver'),
           },
           [person=>[[name=>'yyy']]]);
print narr_xml($tree);
@p = narr_findnode($tree, "person");
ok(grep { narr_tmatch($_, "name", "yyy") } @p);
