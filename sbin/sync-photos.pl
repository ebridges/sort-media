#!/usr/bin/perl -w

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path  qw(make_path remove_tree);
use Log::Log4perl qw(get_logger);
use MediaFile;
use Config::IniFiles;

my $account=shift;
die_usage()
    unless $account;

my $env = 'DEVELOPMENT';
if (defined $ENV{IMGSORTER_ENV}) {
    $env = $ENV{IMGSORTER_ENV};
}
my $ini = 'etc/config.ini';
my $cfg = Config::IniFiles->new( -file => $ini );

my $COPY_DESTINATION = $cfg->val( $env, 'copy-destination' );
my $LOGGING_CONFIG = $cfg->val( $env, 'logging-config' );
my $LOCAL_DIR = $cfg->val( $env, 'local-directory' );
my $REMOTE_DIR = $cfg->val( $env, 'remote-directory' );
my $INCLUDES_FILE = $cfg->val( $env, 'includes-file' );
my $RCLONE_PATH = $cfg->val( $env, 'rclone-path' );

Log::Log4perl->init($LOGGING_CONFIG);
my $LOG = get_logger();

my $CONNECT_CONFIG="./$account-rclone.conf";
die "Configuration not found at $CONNECT_CONFIG"
    unless -e $CONNECT_CONFIG;

make_path $LOCAL_DIR
    unless -e $LOCAL_DIR;

my $rclone_sync="$RCLONE_PATH sync '$REMOTE_DIR' '$LOCAL_DIR' --config $CONNECT_CONFIG --include-from '$INCLUDES_FILE' --verbose"; # --dry-run";

$LOG->info("Beginning sync from $REMOTE_DIR");
`$rclone_sync`;
$LOG->logdie("Error when sync'ing from remote: $?")
    if $?;
$LOG->info("Completed sync from $REMOTE_DIR");

my @files = &list_files($LOCAL_DIR);
my $TOTAL = scalar @files;
my @copied;
my $COUNT = 0;

$LOG->info("beginning processing of $TOTAL files.");

IMAGE: for(@files) {
    chomp;
    my $image = $_;
    my $mediaFile = new MediaFile("$LOCAL_DIR/$image");
    
    my $valid = $mediaFile->validate();
    if (not $valid) {
	$LOG->logwarn("image type not accepted for processing: [$image]");
	next IMAGE;
    } else {
	$LOG->debug("image accepted for processing: [$image]");
    }

    ## extract create date of image, formatted as yyyy-mm-dd
    my $ok = $mediaFile->create_date();
    if(not $ok) {
	$LOG->logwarn("unable to extract create date for image [$image]");
	next IMAGE;
    }

    my $dest_image = $mediaFile->format_dest_filepath($COPY_DESTINATION);
    $LOG->logdie("dest image already exists! ($dest_image) from ($image)")
	unless not -e $dest_image;

    $LOG->debug("copying [$image] to [$dest_image]");
    
    my $successful = $mediaFile->copy_to_dest($dest_image);
    if($successful) {
	$COUNT++;
	push @copied, $image;
    } else {
	$LOG->error("unable to copy [$image] to [$dest_image]: $!");
	next IMAGE;
    }
}

$LOG->info("OK: $COUNT/$TOTAL files sorted");
$LOG->debug("Files processed:\n" . join("\n", @copied));

my $rclone_rm="$RCLONE_PATH delete '%s:%s' --config $CONNECT_CONFIG --verbose --dry-run";
for (@copied) {
    chomp;
    my $cmd = sprintf $rclone_rm, $REMOTE_DIR, $_;
    $LOG->debug("deleting [$REMOTE_DIR/$_] from remote.");
    `$cmd`;
    $LOG->logdie("Error when deleting [$REMOTE_DIR/$_] from remote: $?")
	if $?;
}

my $PURGE = undef;
remove_tree $LOCAL_DIR
    if $PURGE;

sub die_usage {
    my $mesg = "Usage: $0 [useraccount]\n";
    die $mesg; 
}

sub list_files {
    my $directory = shift;
    $LOG->debug("listing files from directory [$directory].");
    opendir my $dir, $directory or die "Cannot open directory ($directory): $!";
    my @files =  grep {  !/^\./ && -f "$directory/$_" } readdir $dir;
    closedir $dir;
    return @files;
}
