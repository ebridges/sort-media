use strict;
use warnings;
use lib '../lib';

use Log::Log4perl qw(get_logger);
Log::Log4perl->init('./test_log4perl.conf');
our $LOG = get_logger();

use Util;

my $candidate_file = $0;
my $expected_uuid = &candidate_uuid($candidate_file);
my $actual_uuid = Util::calc_uuid($candidate_file);

# print "expected: $expected_uuid\n";
# print "actual:   $actual_uuid\n";
&assert($expected_uuid eq $actual_uuid, "expected[$expected_uuid]\nactual  [$actual_uuid]");

sub candidate_uuid {
    my $file = shift;
    my $result = `uuid -v5 ns:URL $file`;
    chomp $result;
    return $result;
}

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	    unless $bool;
}