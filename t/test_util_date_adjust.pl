use strict;
use warnings;
use lib '../lib';

use Util;

use constant DATE_1 => '2034-04-30T16:14:00';
use constant DATE_2 => '2012-09-04T23:20:00';
use constant TIME_ZONE => 'America/New_York';

my $diff = Util::date_diff(DATE_1, DATE_2);

die "diff undef"
    unless $diff;

my $date_1 =  DateTime::Format::ISO8601->parse_datetime( DATE_1 );
my $date_2 =  DateTime::Format::ISO8601->parse_datetime( DATE_2 );

my $actual = Util::adjust_date( $date_1, $diff, TIME_ZONE );
my $expected = DateTime::Format::ISO8601->parse_datetime( DATE_2 );


assert( (DateTime->compare($actual, $expected) == 0), 
	"expected date [$expected] but was [$actual]");

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
