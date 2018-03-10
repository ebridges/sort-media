#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path  qw(make_path remove_tree);
use Log::Log4perl qw(get_logger);
use MediaFile;
use Config::IniFiles;
use POSIX qw/strftime/;
use ImageMetaInfoDB;

my $config=shift;
my $author=shift;
die_usage()
    unless $config;

die "Configuration not found at [$config]"
    unless -e $config;

my $env = 'DEVELOPMENT';
if (defined $ENV{IMGSORTER_ENV}) {
    $env = $ENV{IMGSORTER_ENV};
}
my $ini = 'etc/config.ini';
my $cfg = Config::IniFiles->new( -file => $ini );

my $COPY_IMAGE_DESTINATION = $cfg->val( $env, 'copy-image-destination' );
my $COPY_VIDEO_DESTINATION = $cfg->val( $env, 'copy-video-destination' );
my $LOGGING_CONFIG = $cfg->val( $env, 'logging-config' );
my $today = strftime('%Y-%m-%d',localtime);
my $LOCAL_DIR = $cfg->val( $env, 'local-directory' ) . '-' . $today;
my $REMOTE_DIR = $cfg->val( $env, 'remote-directory' );
my $INCLUDES_FILE = $cfg->val( $env, 'includes-file' );
my $RCLONE_PATH = $cfg->val( $env, 'rclone-path' );
my $REMOVE_REMOTE_FILES = $cfg->val( $env, 'remove-remote-files' );
my $PURGE_LOCAL_DIR = $cfg->val( $env, 'purge-local-dir');
my $IMAGE_DATABASE = $cfg->val( $env, 'image-database');

my %tags = ();

if($author) {
    %tags = (
        'XMP:Creator' => $author,
        'exif:Artist' => $author
    );
}

Log::Log4perl->init($LOGGING_CONFIG);
my $LOG = get_logger();

my $DB = new ImageMetaInfoDB($IMAGE_DATABASE);

make_path $LOCAL_DIR
    unless -e $LOCAL_DIR;

my $rclone_sync="$RCLONE_PATH sync '$REMOTE_DIR' '$LOCAL_DIR' --config $config --include-from '$INCLUDES_FILE' --verbose";
my $rclone_rm="$RCLONE_PATH delete '%s/%s' --config $config --verbose";

if(not $REMOVE_REMOTE_FILES) {
    $rclone_rm .= " --dry-run"
}

$LOG->info("Beginning sync from $REMOTE_DIR");
`$rclone_sync`;
$LOG->logdie("Error when sync'ing from remote: $?")
    if $?;
$LOG->info("Completed sync from $REMOTE_DIR");

my @files = &list_files($LOCAL_DIR);
my $TOTAL = scalar @files;
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

    my $destination_dir = undef;
    if($mediaFile->is_image()) {
        $destination_dir = $COPY_IMAGE_DESTINATION;
    } else {
        $destination_dir = $COPY_VIDEO_DESTINATION;
    }
    
    my $dest_image = $mediaFile->format_dest_filepath($destination_dir);
    $LOG->logdie("dest image already exists! ($dest_image) from ($image)")
        unless not -e $dest_image;

    $LOG->info("copying [$image] to [$dest_image]");
    my $successful = $mediaFile->copy_to_dest($dest_image, \%tags);

    if($successful) {
        $DB->save_image_info($mediaFile);
        delete_local_file($LOCAL_DIR, $image);
        delete_remote_file($REMOTE_DIR, $image);
        $COUNT++;
    } else {
        $LOG->error("unable to copy [$image] to [$dest_image]: $!");
        next IMAGE;
    }
}

if ($PURGE_LOCAL_DIR) {
    $LOG->info("removing local sync directory [$LOCAL_DIR]");
    remove_tree $LOCAL_DIR;
}

$LOG->info("OK: $COUNT/$TOTAL files sorted");

sub delete_local_file {
    my $local_dir = shift;
    my $local_file = shift;
    my $file = $local_dir . '/' . $local_file;
    $LOG->info("deleting local copy [$file]");
    unlink $file
        or $LOG->logdie("unable to delete local file [$file]: [$!]");
}

sub delete_remote_file {
    my $remote_dir = shift;
    my $remote_file = shift;
    my $cmd = sprintf $rclone_rm, $remote_dir, $remote_file;
    $LOG->info("deleting remote copy [$REMOTE_DIR/$_].");
    `$cmd`;
    $LOG->logdie("unable to delete remote file [$REMOTE_DIR/$_]: $?")
        if $?;
}

sub die_usage {
    my $mesg = "Usage: $0 [rclone-config] (author)\n";
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

