use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 3;
}
use XML::NestArray qw(:all);
use XML::NestArray::Arr2HTML;
use XML::NestArray::null;
use XML::Handler::XMLWriter;
use FileHandle;
use strict;
use Data::Dumper;

my $tree =
  Node(top=>[
             Node('personset'=>[
                                Node('person'=>[
                                                Node('name'=>'davey'),
                                                Node('address'=>'here'),
                                                Node('description'=>[
                                                                     Node('hair'=>'green'),
                                                                     Node('eyes'=>'two'),
                                                                     Node('teeth'=>5),
                                                                    ]
                                                    ),
                                                Node('pets'=>[
                                                              Node('petname'=>'igor'),
                                                              Node('petname'=>'ginger'),
                                                             ]
                                                    ),
                                                                          
                                               ],
                                     ),
                                Node('person'=>[
                                                Node('name'=>'shuggy'),
                                                Node('address'=>'there'),
                                                Node('description'=>[
                                                                     Node('hair'=>'red'),
                                                                     Node('eyes'=>'three'),
                                                                     Node('teeth'=>1),
                                                                    ]
                                                    ),
                                                Node('pets'=>[
                                                              Node('petname'=>'thud'),
                                                              Node('petname'=>'spud'),
                                                             ]
                                                    ),
                                               ]
                                     ),
                               ]
                  ),
             Node('animalset'=>[
                                Node('animal'=>[
                                                Node('name'=>'igor'),
                                                Node('class'=>'rat'),
                                                Node('description'=>[
                                                                     Node('fur'=>'white'),
                                                                     Node('eyes'=>'red'),
                                                                     Node('teeth'=>50),
                                                                      ],
                                                      ),
                                                 ],
                                      ),
                                Node('animal'=>[
                                                Node('name'=>'thud'),
                                                Node('class'=>'elephant'),
                                                Node('description'=>[
                                                                     Node('skin'=>'grey'),
                                                                     Node('tusks'=>'2'),
                                                                     Node('teeth'=>555),
                                                                      ],
                                                      ),
                                                 ],
                                      ),
                                Node('animal'=>[
                                                Node('name'=>'spud'),
                                                Node('class'=>'gerbil'),
                                                Node('description'=>[
                                                                     Node('fur'=>'brown'),
                                                                     Node('eyes'=>'blue'),
                                                                     Node('teeth'=>32),
                                                                      ],
                                                      ),
                                                 ],
                                      ),
                               ]
                 ),

            ]
      );

# find all people
my @persons = narr_fn($tree, 'person');

# write xml for all red haired people
map {
    print Dumper $_;
    print narr_xml($_)
      if narr_tmatch($_, "hair", "red");
} @persons;

print "desc\n";
my @desc = narr_gn($tree, 'personset/person/description');
map {
    print narr_xml($_);
} @desc;
my @teeth = map {narr_get($_, 'teeth')} @desc;
ok("@teeth" eq '5 1');

# find all people called shuggy
my @p =
  $tree->where("person",
               sub { $_->tmatch(qw(name shuggy)) });
#map {
#    map { print $_->xml } $_->children
#} @p;


sub findperson {
    my $name = shift;
    return sub {
        my $tree = shift;
        return
          grep {
              narr_tmatch($_, 'name', $name)
          } narr_fn($tree, 'person');
    }
}

my $shuggyfinder = findperson("shuggy");

@p = $shuggyfinder->($tree);
map {
    print narr_xml($_);
} @p;

sub mkhairfilter {
    my $col = shift;
    return sub {
        my $tree = shift;
        return
          narr_tmatch($tree, 'hair', $col);
    }
}

sub mkhaspet {
    my $fulltree = shift;
    my $animal = shift;
    return sub {
        my $subtree = shift;
        my @pets = narr_fn($subtree, 'pets');
        my @petnames = map {narr_fv($_, 'petname')} @pets;
        my @animals = 
          grep {
              narr_tmatch($_, 'class', $animal)
            } narr_fn($fulltree, 'animal');
        my %anames = map {$_=>1} map {narr_fv($_, 'name')} @animals;
        return grep {$anames{$_}} @petnames;
    }
}


my $greenhairfilter = mkhairfilter('green');
print "finding green haired people..\n";
@p = grep {$greenhairfilter->($_)} narr_fn($tree, 'person');
map {
    print narr_xml($_);
} @p;
ok(@p == 1);


my $haspetelephant = mkhaspet($tree, "elephant");
@p = grep {$haspetelephant->($_)} narr_fn($tree, 'person');
map {
    print narr_xml($_);
} @p;
ok(@p == 1);
