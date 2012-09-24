use strict;
use warnings;
use lib '../lib';

use Util;

use constant DATE_1 => '2034-04-30T16:14:00';
use constant DATE_2 => '2012-09-04T23:20:00';

my $date_1 =  DateTime::Format::ISO8601->parse_datetime( DATE_1 );
my $date_2 =  DateTime::Format::ISO8601->parse_datetime( DATE_2 );

assert( (not Util::is_before_now($date_1)), 
	"expected date [$date_1] is not before now");

assert( (Util::is_before_now($date_2)),
	"expected date [$date_2] is before now");

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
