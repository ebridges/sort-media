package Util;

use strict;
use warnings;

use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;

use Log::Log4perl qw(get_logger);

our $LOG = get_logger();

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
    my $adjusted = $copy->add_duration($duration);
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
