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
use strict;

my $h = Data::Stag->makehandler(
                                a => sub { my ($self,$stag) = @_;
                                           $stag->set_foo("bar");});
my $stag = Data::Stag->parse(-str=>'(data(a (foo "x")(fee "y")))',
                             -handler=>$h);
print $stag->xml;
ok($stag->getnode_a->get_foo eq 'bar');
