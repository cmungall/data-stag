use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 2;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->new;

# test freeing
my %h =
  (
   species => sub {
       my ($self, $stag) = @_;
       my $clone = $stag->clone;
       $stag->free;
       ($clone, $clone);
   },
   gene_set => 0,
   similarity_set => sub {
       return
   },
  );
my $handler =
  Data::Stag->makehandler(%h);

$stag->parse(-file=>$fn, -handler=>$handler);
print "original:\n";
print $stag->xml;
print "remaining tree:\n";
print $handler->stag->sxpr;

ok(scalar($stag->kids) == 1);
my @sp = $stag->find_species;
ok(@sp == 6);
