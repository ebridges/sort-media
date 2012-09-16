package Util;

use strict;
use warnings;

use Time::Piece;
use Log::Log4perl qw(get_logger);

our $LOG = get_logger();

sub parse_date {
    my $date = shift;
    my @fmts  = @_;
    $LOG->trace("format_date($date, [@fmts]) called.");
    my $t = Time::Piece->strptime($date, @fmts);
    return $t;
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
