use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 4;
}
use Data::Stag qw(:all);

my $fn = shift @ARGV || "t/data/attrs.xml";
my $sxpr = trip($fn,'sxpr');
my $xml = trip($sxpr, 'xml');
my $itext = trip($xml, 'itext');
$xml = trip($itext, 'xml');
my $doc = Data::Stag->parse($xml);
my $href = $doc->find('address/a/@/href');
ok($href eq 'mailto:cjm@fruitfly.org');
my $name = $doc->find('address/a/.');
ok($name eq 'chris mungall');
my $name2 = $doc->findval('address/a');
ok($name eq $name);
$doc->findval('address/a', 'fred');
my $address = $doc->find_address;
print $address->sxpr;
my $name3 = $doc->findval('address/a');
ok($name3 eq 'fred');

sub trip {
    my ($in, $fmt) = @_;
    my $out = "$in.$fmt";
    my $w = Data::Stag->getformathandler($fmt);
    $w->file($out);
    Data::Stag->parse(-file=>$fn, -handler=>$w);
    return $out;
}
