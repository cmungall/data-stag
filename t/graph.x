use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 9;
}
use XML::NestArray qw(:all);
use FileHandle;

my $fn = shift @ARGV || "t/data/eco.el";
my $tree = XML::NestArray->parse($fn);
my ($m) = $tree->getnode('mapping');
if (1) {
    my $p = XML::NestArray->parser($fn);
    $p->handler('graph');
    $p->handler->mapping($tree->getnode('mapping'));
    $p->parse($fn);
    my $g =
 $p->handler->graph;
    my @s = $g->successors('grass');
    print "grass:@s\n";
    my @t = $g->toposort('grass');
    print "top:@t\n";
    my $closure = $g->TransitiveClosure_Floyd_Warshall;
    my @s = $closure->successors('grass');
    print "grass:@s\n";
}
