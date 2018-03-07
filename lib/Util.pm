package Util;

use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;

use Digest::SHA;

use Log::Log4perl qw(get_logger);

our $LOG = get_logger();

## Difference between Macintosh Epoch time (number of seconds since midnight, January 1, 1904 GMT)
## and Unix epoch time (seconds since 1/1/1970)
use constant EPOCH_DIFF => 2082844800;

sub calc_checksum {
    my $filename = shift;

    $LOG->debug("checksum($filename)");

    open my $fh, '<:raw', $filename
        or die "cannnot open $filename";

    $sha = Digest::SHA->new(512);
    $sha->addfile($fh);

    return $sha->hexdigest;
}

sub convert_from_epoch {
    my $epoch = shift;
    $LOG->debug("converting [$epoch] to DateTime");
    my $t = DateTime->from_epoch(epoch => $epoch);
    if (is_before_now($t)) {
        my $debug_date = join ' ', $t->ymd, $t->hms;
        $LOG->debug("conversion resulted in date in the future, assume Mac epoch [$debug_date]");
        $epoch += EPOCH_DIFF;  # assume this is a Mac epoch time, so convert to unix
        $t = DateTime->from_epoch(epoch => $epoch);
    }
    my $debug_date = join ' ', $t->ymd, $t->hms;
    $LOG->debug("conversion resulted in [$debug_date]");
    return $t;
}

sub parse_date {
    my $date = shift;
    my @fmts  = @_;
    $LOG->trace("format_date($date, [@fmts]) called.");
    
    for(@fmts) {
	next 
	    unless $_;
	my $fmt = DateTime::Format::Strptime->new( pattern => $_ );
	my $d = $fmt->parse_datetime($date);
	return $d
	    if($d);
    }

    return undef;
}

# Takes two dates in ISO8601 format and returns a DateTime::Duration
# object which represents their difference.  
# Assumes param[0] is before param[1]
sub date_diff {
    my $dateStr1 = shift;
    my $dateStr2 = shift;

    my $dt1 = DateTime::Format::ISO8601->parse_datetime( $dateStr1 );
    my $dt2 = DateTime::Format::ISO8601->parse_datetime( $dateStr2 );

    return $dt2->subtract_datetime($dt1);
}

sub adjust_date {
    my $dateOrig = shift;
    my $duration = shift;    
    my $copy = $dateOrig->clone();
    my $adjusted = $copy->subtract_duration($duration);
    return $adjusted;
}

sub is_before_now {
    my $date = shift;
    my $now = DateTime->now();
    my $cmp = DateTime->compare( $date, $now );
    return $cmp < 0;
}

sub trim {
    my $v = shift;
    if(defined $v) {
	$v =~ s/^\s+//g;
	$v =~ s/\s+$//g;
	return length($v) > 0 ? $v : undef;
    } else {
	return undef;
    }
}

1;
