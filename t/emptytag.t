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
use strict;


my $xml =<<EOM
<a>
 <b>foo</b>

 <c></c>
 <d>0</d>
 <e>
   0
 </e>
 <f>




 </f>
</a>
EOM
  ;

my $s = Data::Stag->from('xmlstr', $xml);
# ROUNDTRIP
$s = Data::Stag->from('xmlstr', $s->xml);
print $s->xml;
#print $s->itext;
print $s->sxpr;
print "\n\n";
my $ok = 0;
$s->iterate(sub {
                my $n = shift;
                if ($n->element eq 'c' &&
                    defined $n->data &&
                    $n->data eq '') {
                    $ok = 1;
                }
                return;
            });
ok($ok);

$ok = 0;
$s->iterate(sub {
                my $n = shift;
                if ($n->element eq 'd' &&
                    defined $n->data &&
                    $n->data eq '0') {
                    $ok = 1;
                }
                return;
            });
ok($ok);
