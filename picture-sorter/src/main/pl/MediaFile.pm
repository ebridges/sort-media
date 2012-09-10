use strict;
use warnings;
use Log::Log4perl;

#---------------------------------------------------------------------------------
package MediaFile;

use File::Basename;
use File::Copy;

## dates to use in correcting for bad camera date
use constant CAMERA_DATE => '2034-04-30T16:14:00';
use constant CURRENT_DATE => '2012-09-04T23:20:00';

# only support jpeg since they use EXIF data
## TODO: support .thm files
my @valid_extensions = qw(.jpeg .jpg .JPEG .JPG);

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
my $ISO_8601 = '%Y-%m-%dT%H:%M:%S';
my @dateformats = (
'%Y:%m:%d %H:%M:%S',
'%Y:%m:%d %H:%M:%S%z',
$ISO_8601
);


sub new {
    my $class = shift;
    my $self = {
	srcPath => shift,
    };
    $self->{hasAdjustment} = undef;
    bless $self, $class;
    return $self;
}

sub validate {
    my $self = shift;
    my ($filename, $directories, $suffix) = fileparse($self->{srcPath}, qr/\.[^.]*/);
    if(not grep @valid_extensions, $suffix) {
	return undef;
    }
    $self->{srcFilename} = $filename;
    $self->{srcSuffix} = $suffix;
    1;
}

# Returns and ISO8601 formatted string representing the creation date of the image.
sub create_date {
    get_logger()->debug('create_date() called.');
    # extract created date from EXIF data of image and format as ISO-8601 format
    my $self = shift;
    my $image = $self->{srcPath};
    my $dateObject = &MediaManager::resolve_tags($image, @created_tags);

    $self->{createDate} = undef;
    if($dateObject) {
	get_logger()->debug("got [$dateObject] for [$image].");
	my $now = localtime;
	my $t = &Util::parse_date($dateObject, @dateformats);
	if($t <= $now) {
	    # i.e.: create date is not in the future
	    $self->{createDate} = $t->datetime;
	} else {
	    # create date is in the future and needs adjustment
	    get_logger()->debug("Got a createDate in future, assume camera had wrong date.");
	    $self->{createDate} = $self->_adjust_date($t);
	}
    } else {
	get_logger()->warn("No createDate found in image [$image].");
    }
    return $self->{createDate};
}

sub _adjust_date {
    my $self = shift;
    my $wrong_date = shift;

    my $image = $self->{srcPath};

    my $camera_date = Time::Piece->strptime(CAMERA_DATE, $ISO_8601);
    my $true_date_asof_camera_date = Time::Piece->strptime(CURRENT_DATE, $ISO_8601);

    my $adjustment = $camera_date - $true_date_asof_camera_date;

    $self->{correctedDate} = ($wrong_date - $adjustment);
    $self->{hasAdjustment} = 1;

    return $self->{correctedDate}->datetime;
}

sub copyToDest {
    my $self = shift;
    my $dest = shift;

    my $status = undef;
    
    if($dest ne $self->{destPath}) {
	get_logger()->logdie("invalid state exception: dest_image [$dest] does not match destPath [$self->{destPath}]");
    }

    $status = copy $self->{srcPath}, $dest;

    if($status) {
	get_logger()->info("successfully copied to $dest");
    } else {
	get_logger()->warn("unsuccessfully copied to $dest");
	return $status;
    }

    if($self->{hasAdjustment}) {
	get_logger()->warn("image requires adjustment, adjusting create tags for photo [$dest]");
	$status =  &MediaManager::update_tags(
	    $self->{destPath},
	    $self->{correctedDate},
	    @created_tags
	    );

	if(not $status) {
	    return $status;
	}
    }

    return $status;
}

## format filepath as $destdir/$created/yyyy-mm-ddThh:mm:ss_#.typ
sub format_dest_filepath {
    get_logger()->debug('format_dest_filepath() called.');
    # format the filename for the new image as yyyy-mm-dd_hhmmss_n.typ where
    # 'n' is a serial number incremented if the image exists already, or just '01'
    my $self = shift;
    my $docroot = shift;

    my $created = $self->{createDate};
    my $suffix  = lc $self->{srcSuffix};
    my $date = (split /T/, $created)[0];

    my $destdir = $docroot . '/' . $date;

    if(not -e $destdir) {
	my $successful = mkpath $destdir;
	if(not $successful) {
	    get_logger()->logdie("unable to create dest dir ($destdir): $!\n"); 
	}
    }

    $self->{destPath} = &_make_filepath($destdir, $created, 1, $suffix);
    get_logger()->info("formatted new filepath as [$self->{destPath}]");

    return $self->{destPath};
}

## Formats the complete destination file path for the image.
## If there exists an image already at that location, it increases
## a serial number up to 100 until it no longer finds a duplicate.
## If it exceeds 100 it throws an exception and exits.
sub _make_filepath {
    my $destdir = shift;
    my $created = shift;
    my $serial = shift;
    my $suffix = shift;

    my $name = $destdir . '/' . $created . '_' . sprintf('%02d', $serial) . $suffix;

    # cap recursion at 100 increments
    while($serial < 100 && -e $name) {
	get_logger()->debug("recursing on [$name] since it exists.");
	$name = &make_filepath($destdir, $created, ++$serial, $suffix); 
    }

    if($serial == 100) {
	get_logger()->logdie("too many duplicate image filenames, unable to create new filename for [$name].");
    }

    return $name;
}


#---------------------------------------------------------------------------------
package MediaManager;

use Image::ExifTool qw(:Public);

sub resolve_tags {
    my $img = shift;
    my @tags = @_;
    get_logger()->debug("resolve_tags('$img') called.");
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($img);
    for my $tag (@tags){
	my $value = $exifTool->GetValue($tag);
	my $val = &Util::trim($value);
	if($val) {
	    get_logger()->info("tag [$tag] resolved to [$val]");
	    return $val;
	} else {
	    get_logger()->debug("no value found for tag [$tag]");
	}
    }
    return undef;
}

sub update_tags {
    my $img = shift;
    my $val = shift;
    my @tags = @_;
    get_logger()->debug("update_tags('$img') called.");
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($img);
    for my $tag (@tags){
	my $errmsg;
	my $success;
	($success, $errmsg) = $exifTool->SetValue($_, $val);
	get_logger()->logwarn("unable to update tag [$_] on image [$img] because [$errmsg]")
	    unless $success;
    }
    return 1;
}

#---------------------------------------------------------------------------------
package Util;

use Time::Piece;

sub parse_date {
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


1;
