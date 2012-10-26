use strict;
use warnings;
use lib '../lib';

use Util;

use DateTime::Duration;

# 1y 1m 1w 1d 1h 1m 1s 0ns
my $DURATION = DateTime::Duration->new(
    years       => 1,
    months      => 1,
    weeks       => 0,
    days        => 1,
    hours       => 1,
    minutes     => 1,
    seconds     => 1,
    nanoseconds => 0
    );

my $CASE_1_DATE      = DateTime::Format::ISO8601->parse_datetime( '2034-04-30T16:14:00' );
my $CASE_1_EXPECTED  = DateTime::Format::ISO8601->parse_datetime( '2033-03-29T15:12:59' );

my $CASE_2_DATE      = DateTime::Format::ISO8601->parse_datetime( '2034-04-02T20:59:39' );
my $CASE_2_EXPECTED  = DateTime::Format::ISO8601->parse_datetime( '2033-03-01T19:58:38' );

my $case1actual = Util::adjust_date($CASE_1_DATE, $DURATION);
assert( (DateTime->compare($case1actual, $CASE_1_EXPECTED) == 0), 
	"expected date [$CASE_1_EXPECTED] but was [$case1actual]");

my $case2actual = Util::adjust_date($CASE_2_DATE, $DURATION);
assert( (DateTime->compare($case2actual, $CASE_2_EXPECTED) == 0), 
	"expected date [$CASE_2_EXPECTED] but was [$case2actual]");

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
