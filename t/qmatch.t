use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 4;
}
use Data::Stag;
use strict;

my $s = Data::Stag->unflatten(people=>[
				       person=>{
						name=>'big dave',
						address=>{
							  street=>'foo',
							  city=>'methyl',
							 },
					       },
				       person=>{
						name=>'shuggy',
						address=>{
							  street=>'bar',
							  city=>'auchtermuchty',
							 },
					       },
				       ],
			     );
print $s->xml;

my @persons;
@persons = $s->qmatch('person', (name=>'shuggy'));
ok(@persons == 1);
ok($persons[0]->get('address/city') eq 'auchtermuchty');

@persons = $s->qmatch('person', ('address/street'=>'foo'));
ok(@persons == 1);
ok($persons[0]->get_name eq 'big dave');

