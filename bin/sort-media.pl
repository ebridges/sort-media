#!/usr/bin/perl -w

use strict;
use warnings;

use Time::Piece;
use File::Copy;
use File::Path;
use Log::Log4perl qw(get_logger);
use MediaFile;

use Config::IniFiles;

my $env = $ENV{IMGSORTER_ENV};
my $ini = 'etc/config.ini';
my $cfg = Config::IniFiles->new( -file => $ini );

my $COPY_ENABLED = $cfg->val( $env, 'copy-enabled' );
my $REMOVE_ORIGINAL = $cfg->val( $env, 'remove-original' );
my $WORKING_DIR = $cfg->val( $env, 'working-directory' );
my $COPY_DESTINATION = $cfg->val( $env, 'copy-destination' );
my $LOGGING_CONFIG = $cfg->val( $env, 'logging-config' );

chdir $WORKING_DIR;

Log::Log4perl->init($LOGGING_CONFIG);

my $LOG = get_logger();

# expect list of FQ filenames of source images.
IMAGE: while(<>) {
    chomp;
    ## image filename
    my $image = $_;

    my $mediaFile = new MediaFile($_);
    my $valid = $mediaFile->validate();

    if($valid) {
	$LOG->debug("image accepted for processing: [$image]");
    } else {
	$LOG->warn("image type not accepted for processing: [$image]");
	next IMAGE;
    }

    ## extract create date of image, formatted as yyyy-mm-dd
    my $ok = $mediaFile->create_date();

    if(not $ok) {
	$LOG->warn("unable to extract create date for image [$image]");
	next IMAGE;
    }

    my $dest_image = $mediaFile->format_dest_filepath($COPY_DESTINATION);

    $LOG->logdie("dest image already exists! ($dest_image) from ($image)")
	unless not -e $dest_image;

    if($COPY_ENABLED) {
	my $successful;
	$LOG->debug("copying [$image] to [$dest_image]");
	$successful = $mediaFile->copy_to_dest($dest_image);

	if(not $successful) {
	    $LOG->logdie("unable to copy [$image] to [$dest_image]: $!");
	}

	$successful = undef;
	if($REMOVE_ORIGINAL) {
	    $LOG->debug("removing source image [$image] after successful copy.");
	    $successful = unlink $image;
	    if(not $successful) {
		$LOG->logdie("unable to remove source image [$image]: $!");
	    }
	    $LOG->info("successfully moved [$image] to [$dest_image]");
	} else {
	    $LOG->info("successfully copied [$image] to [$dest_image]");
	}
    }
}
