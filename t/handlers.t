use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->new;

# this handler will take the above file, 
# which consists of the datasets: species, genes
# and similarity-sets (ie pairings of genes), and
# cache the datatypes by their primary keys; it will
# also replace foreign keys with the full record pointed
# to by that foreign key.
my %h =
  (
   species => sub {
       my ($self, $stag) = @_;
       my $species_h = $self->{species_h};
       # cache by primary key:
       $species_h->{$stag->get_tax_id} = $stag;
       0;
   },
   gene => sub {
       my ($self, $stag) = @_;
       my $species_h = $self->{species_h};
       my $gene_h = $self->{gene_h};
       # add new node based on foreign key key:
       $stag->setnode_species($species_h->{$stag->get_tax_id});
       # cache by primary key:
       # [gene symbols do not guarantee uniqueness, but this is
       #  a toy example, OK?]
       printf "CACHING %s\n", $stag->get_symbol;
       $gene_h->{$stag->get_symbol} = $stag;
       0;
   },
   pair => sub {
       my ($self, $stag) = @_;
       my $gene_h = $self->{gene_h};
       # add new node based on foreign key key:
       my @symbols = $stag->get_symbol;
       foreach (@symbols) {
           my $gene =  $gene_h->{$_};
           if ($gene) {
               $stag->add_gene($gene);
           }
           else {
               $stag->add_comment("Dunno what symbol $_ is");
           }
       }
       0;
   },
  );
my $handler =
  Data::Stag->makehandler(%h);
$handler->{species_h} = {};
$handler->{gene_h} = {};

$stag->parse(-file=>$fn, -handler=>$handler);
print $stag->xml;

my ($gene_set) = $stag->fn("gene_set");
my ($species_set) = $stag->fn("species_set");
print $gene_set->xml;
  
my @g = $gene_set->where("gene",
                         sub {
                             shift->tm("symbol", "HGNC")
                         });

ok(@g == 1);
my $chrom = $g[0]->get("map/cytological/chromosome");
ok($chrom eq '6');
ok(grep { $_->tm("binomial", "Homo sapiens") } @g);

@g =
  $gene_set->where('gene',
                   sub { my $g = shift;
                         $g->get("symbol") =~ /^H/ &&
                           $g->findval("common_name") ne ('human')});
ok(@g == 1);
ok(grep { $_->tm("binomial", "Mus musculus") } @g);

my ($ss) = $stag->fn("similarity_set");
print $ss->xml;

sub q_gene_by_phenotype {
    my $gs = shift;
    my $ph = shift;
    $gs->where("gene", 
               sub {
                   grep {/$ph/} shift->get_phenotype
               });
}
sub q_gene_by_go {
    my $gs = shift;
    my $go = shift;
    $gs->where("gene", 
               sub {
                   grep {/$go/} shift->get_GO_term
               });
}

@g = q_gene_by_phenotype($gene_set, "Hemo");
ok(@g == 1);
@g = q_gene_by_phenotype($gene_set, "Zzz");
ok(@g == 0);
@g = q_gene_by_go($gene_set, "iron");
ok(@g == 1);
@g = q_gene_by_go($gene_set, "");
ok(@g == 2);

my @names = ();
$gene_set->iterate(sub{push(@names, shift->name)});
print "names=@names\n";

$gene_set->iterate(sub {
                       my $node= shift;
                       my $parent = shift;
                       printf "%s=>%s\n", $parent ? $parent->name : '', $node->name;
                   });


