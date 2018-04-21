use strict;
use warnings;
use lib '../lib';

use Log::Log4perl qw(get_logger);
Log::Log4perl->init('t/test_log4perl.conf');
our $LOG = get_logger();

use Util;

use constant DATE_01 => '2034-04-30T16:14:00';
use constant DATE_02 => '2012-09-04T23:20:00';
use constant DATE_03 => '2012:11:11 11:00:11';
use constant DATE_04 => '2012:11:11 11:00:11-0400';
use constant DATE_05 => '2012:11:11 11:00-0400';
use constant DATE_06 => '0000:00:00 00:00:00';
use constant DATE_07 => '2012-11-11 11:00:11';
use constant DATE_08 => '2012-11-11 11:00:11-0400';
use constant DATE_09 => '2012-11-11 11:00-0400';
use constant DATE_10 => '0000-00-00 00:00:00';
use constant DATE_11 => 'Fri Dec 30 18:29:18 2005';


my @dateformats = (
  '%Y:%m:%d %H:%M:%S',
  '%Y:%m:%d %H:%M:%S%z',
  '%Y:%m:%d %H:%M%z',
  '%Y-%m-%d %H:%M:%S',
  '%Y-%m-%d %H:%M:%S%z',
  '%Y-%m-%d %H:%M%z',
  '%Y-%m-%dT%H:%M:%S',
  '%a %b %d %H:%M:%S %Y'
);


my $date_1 = Util::parse_date(DATE_01, @dateformats);
$LOG->trace("date_01: $date_1");
assert( defined($date_1), 'unable to parse ' . DATE_01 );

my $date_2 = Util::parse_date(DATE_02, @dateformats);
$LOG->trace("date_02: $date_2");
assert( defined($date_2), 'unable to parse ' . DATE_02 );

my $date_3 = Util::parse_date(DATE_03, @dateformats);
$LOG->trace("date_03: $date_3");
assert( defined($date_3), 'unable to parse ' . DATE_03 );

my $date_4 = Util::parse_date(DATE_04, @dateformats);
$LOG->trace("date_04: $date_4");
assert( defined($date_4), 'unable to parse ' . DATE_04 );

my $date_5 = Util::parse_date(DATE_05, @dateformats);
$LOG->trace("date_05: $date_5");
assert( defined($date_5), 'unable to parse ' . DATE_05 );

my $date_6 = Util::parse_date(DATE_06, @dateformats);
#$LOG->trace("date_06: $date_6");
assert( not (defined($date_6)), 'error: unable to parse ' . DATE_06 );

my $date_7 = Util::parse_date(DATE_07, @dateformats);
#$LOG->trace("date_07: $date_7");
assert( not (defined($date_7)), 'error: unable to parse ' . DATE_07 );

my $date_8 = Util::parse_date(DATE_08, @dateformats);
#$LOG->trace("date_08: $date_8");
assert( not (defined($date_8)), 'error: unable to parse ' . DATE_08 );

my $date_9 = Util::parse_date(DATE_09, @dateformats);
#$LOG->trace("date_09: $date_9");
assert( not (defined($date_9)), 'error: unable to parse ' . DATE_09 );

my $date_10 = Util::parse_date(DATE_10, @dateformats);
#$LOG->trace("date_10: $date_10");
assert( not (defined($date_10)), 'error: unable to parse ' . DATE_10 );

my $date_11 = Util::parse_date(DATE_11, @dateformats);
#$LOG->trace("date_11: $date_11");
assert( not (defined($date_11)), 'error: unable to parse ' . DATE_11 );

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
