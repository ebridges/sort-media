package MediaFile;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use File::Basename;
use File::Copy;
use File::Path;
use Time::Piece;
use MediaManager;
use Util;

## dates to use in correcting for bad camera date
use constant CAMERA_DATE => '2034-04-30T16:14:00';
use constant CURRENT_DATE => '2012-09-04T23:20:00';

our $LOG = get_logger();

# only support jpeg since they use EXIF data
## TODO: support .thm files
my @valid_extensions = qw(.jpeg .jpg .JPEG .JPG);

# look for these tags in this order
my @created_tags = (
  'CreateDate',
  'CreateDate (1)',
  'Create Date',
  'DateTimeDigitized',
  'Date/Time Original',
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
    $LOG->trace('create_date() called.');
    # extract created date from EXIF data of image and format as ISO-8601 format
    my $self = shift;
    my $image = $self->{srcPath};
    my $dateObject = &MediaManager::resolve_tags($image, @created_tags);

    if($LOG->is_trace()) {
	MediaManager::dump_tags_trace($image);
    }

    $self->{createDate} = undef;
    if($dateObject) {
	$LOG->debug("got [$dateObject] for [$image].");
	my $now = localtime;
	my $t = &Util::parse_date($dateObject, @dateformats);
	if($t <= $now) {
	    # i.e.: create date is not in the future
	    $self->{createDate} = $t;
	} else {
	    # create date is in the future and needs adjustment
	    $LOG->debug("Got a createDate in future, assume camera had wrong date.");
	    $self->{createDate} = $self->adjust_date($t);
	}
    } else {
	$LOG->debug("No createDate found in image [$image].");
    }
    return $self->{createDate};
}

sub adjust_date {
    my $self = shift;
    my $wrong_date = shift;

    my $image = $self->{srcPath};

    my $camera_date = Time::Piece->strptime(CAMERA_DATE, $ISO_8601);
    my $true_date_asof_camera_date = Time::Piece->strptime(CURRENT_DATE, $ISO_8601);

    my $adjustment = $camera_date - $true_date_asof_camera_date;

    $self->{correctedDate} = ($wrong_date - $adjustment);
    $self->{hasAdjustment} = 1;

    return $self->{correctedDate};
}

sub copy_to_dest {
    my $self = shift;
    my $dest = shift;

    my $status = undef;
    
    if($dest ne $self->{destPath}) {
	$LOG->logdie("invalid state exception: dest_image [$dest] does not match destPath [$self->{destPath}]");
    }

    $status = copy $self->{srcPath}, $dest;

    if($status) {
	$LOG->debug("successfully copied to $dest");
    } else {
	return $status;
    }

    if($self->{hasAdjustment}) {
	$LOG->warn("image requires adjustment, updating create date tags for photo [$dest] to be [$self->{correctedDate}]");
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

## format filepath as $destdir/yyyy-mm-dd/yyyymmdd_hhmmss_nn.typ
sub format_dest_filepath {
    $LOG->trace('format_dest_filepath() called.');
    # format the filename for the new image as yyyymmdd_hhmmss_nn.typ where
    # 'nn' is a serial number incremented if the image exists already, or just '01'
    my $self = shift;
    my $docroot = shift;

    my $created = $self->{createDate};
    my $suffix  = lc $self->{srcSuffix};
    my $date = $created->ymd;

    my $destdir = $docroot . '/' . $date;

    if(not -e $destdir) {
	my $successful = mkpath $destdir;
	if(not $successful) {
	    $LOG->logdie("unable to create dest dir ($destdir): $!\n"); 
	}
    }

    $self->{destPath} = &make_filepath($destdir, $created, 1, $suffix);
    $LOG->debug("formatted new filepath as [$self->{destPath}]");

    return $self->{destPath};
}

## Formats the complete destination file path for the image.
## If there exists an image already at that location, it increases
## a serial number up to 100 until it no longer finds a duplicate.
## If it exceeds 100 it throws an exception and exits.
sub make_filepath {
    my $destdir = shift;
    my $created = shift;
    my $serial = shift;
    my $suffix = shift;

    $created->date_separator('');
    $created->time_separator('');
    my $name = $destdir . '/' . $created->datetime . '_' . sprintf('%02d', $serial) . $suffix;

    # cap recursion at 100 increments
    while($serial < 100 && -e $name) {
	$LOG->debug("recursing on [$name] since it exists.");
	$name = &make_filepath($destdir, $created, ++$serial, $suffix); 
    }

    if($serial == 100) {
	$LOG->logdie("too many duplicate image filenames, unable to create new filename for [$name].");
    }

    $created->time_separator(':');
    $created->date_separator('-');
    return $name;
}

1;
