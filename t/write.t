use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 1;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $tree = Data::Stag->new;
$tree->parse($fn);
$tree->write("t/data/test.sxpr", "sxpr");
my $nu = Data::Stag->parse("t/data/test.sxpr");
print $nu->sxpr;
 ok($nu->find('pair'));
