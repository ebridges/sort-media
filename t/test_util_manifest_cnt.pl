use strict;
use warnings;
use lib '../lib';
use Log::Log4perl qw(get_logger);

use Manifest;

use constant MANIFEST_ROOT => "/tmp/sort-media-test-$$";

Log::Log4perl->init('./test_log4perl.conf');

my $LOG = get_logger();

my $mf = new Manifest(MANIFEST_ROOT);

assert( (defined($mf)), "got invalid manifest");

assert( ($mf->cnt_successful() == 0), "got invalid successful count: " . $mf->cnt_successful());
assert( ($mf->cnt_unsuccessful() == 0), "got invalid unsuccessful count: " . $mf->cnt_unsuccessful());

$mf->log_successful("file_a");
$mf->log_unsuccessful("file_b");

assert( ($mf->cnt_successful() == 1), "got invalid successful count: " . $mf->cnt_successful());
assert( ($mf->cnt_unsuccessful() == 1), "got invalid unsuccessful count: " . $mf->cnt_unsuccessful());

$mf->log_successful("file_c");
$mf->log_unsuccessful("file_d");

assert( ($mf->cnt_successful() == 2), "got invalid successful count: " . $mf->cnt_successful());
assert( ($mf->cnt_unsuccessful() == 2), "got invalid unsuccessful count: " . $mf->cnt_unsuccessful());

sub assert {
    my $bool = shift;
    my $mesg = shift;
    warn $mesg . "\n"
	unless $bool;
}
