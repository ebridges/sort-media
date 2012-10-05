#!/usr/bin/perl -w

use strict;
use warnings;

use File::Copy;
use File::Path;
use Log::Log4perl qw(get_logger);
use MediaFile;
use Manifest::File;
use Config::IniFiles;

my $env = $ENV{IMGSORTER_ENV};
my $ini = 'etc/config.ini';
my $cfg = Config::IniFiles->new( -file => $ini );

my $COPY_ENABLED = $cfg->val( $env, 'copy-enabled' );
my $REMOVE_ORIGINAL = $cfg->val( $env, 'remove-original' );
my $WORKING_DIR = $cfg->val( $env, 'working-directory' );
my $COPY_DESTINATION = $cfg->val( $env, 'copy-destination' );
my $LOGGING_CONFIG = $cfg->val( $env, 'logging-config' );
my $REPOSITORY_URI = $cfg->val( $env, 'repository-uri' );

chdir $WORKING_DIR;

Log::Log4perl->init($LOGGING_CONFIG);

my $LOG = get_logger();

my $user = shift;

die_usage()
    unless $user;

my $manifest = File->new($REPOSITORY_URI . '/' . $user);

my @files = @{ $manifest->read() };
my $TOTAL = scalar @files;
my $COUNT = 0;

$LOG->info("beginning processing of $TOTAL files.");

IMAGE: for(@files) {
    chomp;
    ## image filename
    my $image = $_;

    my $mediaFile = new MediaFile($_);
    my $valid = $mediaFile->validate();

    if($valid) {
	$LOG->debug("image accepted for processing: [$image]");
    } else {
	$LOG->warn("image type not accepted for processing: [$image]");
	$manifest->log_unsuccessful($image);
	next IMAGE;
    }

    ## extract create date of image, formatted as yyyy-mm-dd
    my $ok = $mediaFile->create_date();

    if(not $ok) {
	$LOG->warn("unable to extract create date for image [$image]");
	$manifest->log_unsuccessful($image);
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
	    $manifest->log_unsuccessful($image);
	    $LOG->error("unable to copy [$image] to [$dest_image]: $!");
	} else {
	    $COUNT++;
	}

	$successful = undef;
	if($REMOVE_ORIGINAL) {
	    $LOG->debug("marking source image [$image] for removal after successful copy.");
	    # $successful = unlink $image;
	    # if(not $successful) {
	    # 	$LOG->logdie("unable to remove source image [$image]: $!");
	    # }
	    $manifest->log_successful($image);
	    $LOG->info("OK: mv [$image] : [$dest_image]");
	} else {
	    $LOG->info("OK: cp [$image] : [$dest_image]");
	}
    }

}

$manifest->write();

$LOG->warn("OK: $COUNT/$TOTAL files sorted");

sub die_usage {
    my $mesg = "Usage: $0 [useraccount]\n";
    die $mesg; 
}
