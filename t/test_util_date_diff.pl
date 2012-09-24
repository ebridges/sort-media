use strict;
use warnings;
use lib '../lib';

use Util;

use constant DATE_1 => '2034-04-30T16:14:00';
use constant DATE_2 => '2012-09-04T23:20:00';

my $diff = Util::date_diff(DATE_1, DATE_2);

die "diff undef"
    unless $diff;

assert( ($diff->years()  == 21), 'expected 21 years but was ' . $diff->years());
assert( ($diff->months() == 7),  'expected 7 months but was ' . $diff->months());
assert( ($diff->days() == 4),    'expected 4 days but was ' . $diff->days());
assert( ($diff->hours() == 16),  'expected 16 hours but was ' . $diff->hours());

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
