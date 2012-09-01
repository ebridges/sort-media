#!/usr/bin/perl

use strict;
use warnings;
use Image::ExifTool qw(:Public);
use File::Path;
use File::Copy;
use File::Basename;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

use constant WD => '/Users/ebridges/Documents/Projects/photo-utils/picture-sorter';
use constant DEST => 'target/';

# only support jpeg since they use EXIF data
my @exts = qw(.jpeg .jpg);

# look for these tags in this order
my @created_tags = q(
'CreateDate',
'datecreate',
'CreateDate (1)',
'DateTimeDigitized',
'DateTimeOriginal',
'DateTimeOriginal (1)'
);

# these tags appear to use the mapped format
my %tag_dateformats = q(
'CreateDate' => '%Y:%m:%d %H:%M:%S%z',
'datecreate' => '%Y-%m-%dT%H:%M:%S%z',
'CreateDate (1)' => '%Y:%m:%d %H:%M:%S%z',
'DateTimeDigitized' => '%Y:%m:%d %H:%M:%S%z',
'DateTimeOriginal' => '%Y:%m:%d %H:%M:%S',
'DateTimeOriginal (1)' => '%Y:%m:%d %H:%M:%S'
);

chdir WD;

# expect list of FQ filenames of source images.
IMAGE: while(<>) {
    ## image filename
    my $image = $_;

    my ($filename, $directories, $suffix) = fileparse($image, qr/\.[^.]*/);
    if(not grep @exts, $suffix) {
	if(not &handle_alternates($image)) {
	    get_logger()->warn("image [$image] is not supported, skipping");
	    next IMAGE;
	}
    }

    ## extract create date of image, formatted as yyyy-mm-dd
    my $created = &create_date($image);

    if(not $created) {
	get_logger()->warn("unable to extract create date for image [$image]");
	next IMAGE;
    }

    my $dest_image = &format_dest_filename(DEST, $created, $suffix);

    die "dest image already exists! ($dest_image) from ($image)"
	unless not -e $dest_image;

    my $successful = move $image, $dest_image;
    if(not $successful) {
	get_logger()->error("unable to move [$image] to [$dest_image]: $!");
	die("can't create files in destination folder. ($!)");
    }
}

sub handle_alternates {
    # not yet implemented

    # THM/AVI
    # * get the create date from the THM and move both together.
    #
    # PNG
    # * ExifTool supports this, so maybe just let it go through normal flow?

    return undef;
}

sub create_date {
    get_logger()->debug('create_date() called.');
    # extract created date from EXIF data of image and format as ISO-8601 format
    my $image = shift;
    my $createDate = &resolve_tags($image, @created_tags);
    return $createDate;
}

## format filename as $destdir/$created/yyyy-mm-ddThh:mm:ss_#.typ
sub format_dest_filename {
    get_logger()->debug('format_dest_filename() called.');
    # TODO
    # format the filename for the new image as yyyy-mm-dd_hhmmss_n.typ where
    # 'n' is a serial number incremented if the image exists already, or just '01'
    my $docroot = shift;
    my $created = shift;
    my $suffix  = shift;

    my $destdir = $docroot . '/' . $created;

    if(not -e $destdir) {
	my $successful = mkpath $destdir;
	if(not $successful) {
	    get_logger()->error("unable to create dest dir ($destdir): $!\n"); 
	    die("can't create destination folders. ($!)");
	}
    }

    my $filename = &make_filename($destdir, $created, 1, $suffix);
    get_logger()->info("formatted new filename as [$filename]");

    return $filename;
}

sub make_filename {
    my $destdir = shift;
    my $created = shift;
    my $serial = shift;
    my $suffix = shift;

    my $name = $destdir . '/' . $created . '_' . sprintf('%02d', $serial) . $suffix;

    # cap recursion at 100 increments
    while($serial < 100 && -e $name) {
	get_logger()->info("recursing on [$name] since it exists.");
	$name = &make_filename($destdir, $created, ++$serial, $suffix); 
    }

    return $name;
}

sub resolve_tags {
    my $img = shift;
    my @tags = @_;
    get_logger()->debug("resolve_tags('$img') called.");
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($img);
    for my $tag (@tags){
	my $val = $exifTool->GetValue($tag);
	$val = &trim($val);
	if($val) {
	    get_logger()->info("found value for tag [$tag]");
	    return 
		format_date(
		    $tag_dateformats{$tag}, 
		    $val
		);
	}
    }
    return undef;
}

sub format_date {
    my $fmt  = shift;
    my $date = shift;
    get_logger()->debug('format_date() called.');
    my $t = Time::Piece->strptime($date, $fmt);
    my $d = $t->datetime;
    get_logger()->info("Converted [$date] to [$d] using format [$fmt]");
    return $d;
}

sub trim {
    my $v = shift;
    $v =~ s/^\s+//g;
    $v =~ s/\s+$//g;
    return length($v) > 0 ? $v : undef;
}
