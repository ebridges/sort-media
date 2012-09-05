#!/usr/bin/perl -w

use strict;
use warnings;
use Image::ExifTool qw(:Public);
use Time::Piece;
use File::Path;
use File::Copy;
use File::Basename;
use Log::Log4perl;

use constant ENABLED => 'yes';
use constant REMOVE_ORIGINAL => undef;
use constant WD => '/home/imgsorter';
use constant DEST => '/c/photos/incoming';
use constant LOG_CONFIG => 'etc/log4perl.conf';

chdir WD;

Log::Log4perl->init(LOG_CONFIG);

# only support jpeg since they use EXIF data
## TODO: support .thm files
my @exts = qw(.jpeg .jpg .JPEG .JPG);

# look for these tags in this order
my @created_tags = (
'CreateDate',
'datecreate',
'CreateDate (1)',
'DateTimeDigitized',
'DateTimeOriginal',
'DateTimeOriginal (1)'
);

# creation dates are stored in the following formats 
my @dateformats = (
'%Y:%m:%d %H:%M:%S',
'%Y:%m:%d %H:%M:%S%z',
'%Y-%m-%dT%H:%M:%S%z'
);

# expect list of FQ filenames of source images.
IMAGE: while(<>) {
    chomp;
    ## image filename
    my $image = $_;

    my ($filename, $directories, $suffix) = fileparse($image, qr/\.[^.]*/);
    if(not grep @exts, $suffix) {
	if(not &handle_alternates($image)) {
	    get_logger()->warn("image [$image] is not supported, skipping");
	    next IMAGE;
	}
    } else {
	get_logger()->info("image accepted for processing: [$image]");
    }

    ## extract create date of image, formatted as yyyy-mm-dd
    my $created = &create_date($image);

    if(not $created) {
	get_logger()->warn("unable to extract create date for image [$image]");
	next IMAGE;
    }

    my $dest_image = &format_dest_filename(DEST, $created, $suffix);

    get_logger()->logdie("dest image already exists! ($dest_image) from ($image)")
	unless not -e $dest_image;

    if(ENABLED) {
	my $successful;
	get_logger()->info("copying [$image] to [$dest_image]");
	$successful = copy $image, $dest_image;
	
	if(not $successful) {
	    get_logger()->logdie("unable to copy [$image] to [$dest_image]: $!");
	}

	$sucessful = undef;
	if(REMOVE_ORIGINAL) {
	    get_logger()->info("removing source image [$image] after successful copy.");
	    $successful = unlink $image;
	}

	if(not $successful) {
	    get_logger()->logdie("unable to remove source image [$image]: $!");
	}
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

    if($createDate) {
	get_logger()->debug("got [$createDate] for [$image].");
	my $now = localtime;
	my $t = format_date($createDate, @dateformats);
	if($t < $now) {
	    return $t->datetime;
	} else {
	    get_logger()->debug("Got a createDate in future, trying to use modification date.");
	    return modify_date($image);
	}
    } else {
	get_logger()->debug("No createDate found in image, trying to use modification date.");
	return modify_date($image);
    }
}

sub modify_date {
    get_logger()->debug('modify_date() called.');
    # extract modify date from EXIF data of image and format as ISO-8601 format
    my $modifyDate = &resolve_tags($image, @modify_tags);

    if($modifyDate) {
	get_logger()->debug("got [$modifyDate] for [$image].");
	my $now = localtime;
	my $t = format_date($modifyDate, @dateformats);
	if($t < $now) {
	    return $t->datetime;
	} else {
	    get_logger()->debug("Got a modifyDate image is unreadable.");
	    return undef;
	}	
    } else {
	return undef;	
    }
}

## format filename as $destdir/$created/yyyy-mm-ddThh:mm:ss_#.typ
sub format_dest_filename {
    get_logger()->debug('format_dest_filename() called.');
    # format the filename for the new image as yyyy-mm-dd_hhmmss_n.typ where
    # 'n' is a serial number incremented if the image exists already, or just '01'
    my $docroot = shift;
    my $created = shift;
    my $suffix  = shift;
    my $date = (split /T/, $created)[0];

    my $destdir = $docroot . '/' . $date;

    if(not -e $destdir) {
	my $successful = mkpath $destdir;
	if(not $successful) {
	    get_logger()->logdie("unable to create dest dir ($destdir): $!\n"); 
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
	get_logger()->debug("recursing on [$name] since it exists.");
	$name = &make_filename($destdir, $created, ++$serial, $suffix); 
    }

    if($serial == 100) {
	get_logger()->logdie("too many duplicate image filenames, unable to create new filename for [$name].");
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
	my $value = $exifTool->GetValue($tag);
	my $val = &trim($value);
	if($val) {
	    get_logger()->info("tag [$tag] resolved to [$val]");
	    return $val;
	} else {
	    get_logger()->debug("no value found for tag [$tag]");
	}
    }
    return undef;
}

sub format_date {
    my $date = shift;
    my @fmts  = @_;
    get_logger()->debug("format_date($date, [@fmts]) called.");
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
