package Manifest;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);

our $LOG = get_logger();

sub new {
    $LOG->trace("Manifest::new() called.");
    for(@_){
	$LOG->trace("  > param($_)");
    }
    my $class = shift;
    my $self = {};
    $self->{'manifest_uri'} = shift;
    $self->{'successful'} = ();
    $self->{'unsuccessful'} = ();
    bless $self, $class;
    return $self;
}

sub read {
    $LOG->logdie("Manifest::read() is abstract\n");
}

sub write {
    $LOG->logdie("Manifest::write() is abstract\n");
}

sub cnt_successful {
    my $self = shift;
    if(defined($self->{'successful'})) {
	return scalar @{$self->{'successful'}};
    } else {
	return 0;
    }
}

sub cnt_unsuccessful {
    my $self = shift;
    if(defined($self->{'unsuccessful'})) {
	return scalar @{$self->{'unsuccessful'}};
    } else {
	return 0;
    }
}

sub log_successful {
    my $self = shift;
    my $file = shift;
    push @{$self->{'successful'}}, $file;
}

sub log_unsuccessful {
    my $self = shift;
    my $file = shift;
    push @{$self->{'unsuccessful'}}, $file;
}

