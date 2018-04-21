use strict;
use warnings;
use lib '../lib';

use Log::Log4perl qw(get_logger);
Log::Log4perl->init('./t/test_log4perl.conf');
our $LOG = get_logger();

use Util;

my $candidate_file = $0;
my $expected_checksum = &candidate_checksum($candidate_file);
my $actual_checksum = Util::calc_checksum($candidate_file);

&assert($expected_checksum eq $actual_checksum, "expected[$expected_checksum]\nactual  [$actual_checksum]");

sub candidate_checksum {
    my $file = shift;
    my $result = `shasum -a 512 $file`;
    chomp $result;
    return (split /\s+/, $result)[0];
}

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
