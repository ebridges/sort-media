package MediaFile;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use File::Basename;
use File::Copy;
use File::Path;
use Image::ExifTool qw(:Public);

use MediaManager;
use Util;

## dates to use in correcting for bad camera date
use constant CAMERA_DATE => '2034-04-30T16:14:00';
use constant CURRENT_DATE => '2012-09-04T23:20:00';

our $LOG = get_logger();

my @valid_extensions = qw(.jpeg .jpg .JPEG .JPG .mp4 .MP4 .avi .AVI .mov .MOV .png .PNG .3gp .3GP);
my @image_extensions = qw(.jpeg .jpg .png);

# look for these tags in this order
my @created_tags = (
  'CreateDate',
  'DateTimeDigitized',
  'DateTimeOriginal',
  'MediaCreateDate',
  'FileModifyDate'
);

# creation dates are stored in the following formats 
my $ISO_8601 = '%Y-%m-%dT%H:%M:%S';
my @dateformats = (
  '%Y:%m:%d %H:%M:%S',
  '%Y:%m:%d %H:%M:%S%z',
  '%Y:%m:%d %H:%M%z', 
  '%a %b %d %H:%M:%S %Y', #  Fri Dec 30 18:29:18 2005
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
    if(grep {/$suffix/} @valid_extensions) {
        $self->{srcFilename} = $filename;
        $self->{srcSuffix} = $suffix;
        return 1;
    }
    undef;
}

sub is_image {
    my $self = shift;
    my ($filename, $directories, $suffix) = fileparse($self->{srcPath}, qr/\.[^.]*/);
    $suffix = lc($suffix);
    if(grep {/$suffix/} @image_extensions) {
        return 1;
    }
    undef;
}

# Returns a DateTime object representing the creation date of the image.
sub create_date {
    $LOG->trace('create_date() called.');
    # extract created date from EXIF data of image and format as ISO-8601 format
    my $self = shift;
    my $image = $self->{srcPath};
    my $dateString = &MediaManager::resolve_tags($image, @created_tags);

    if($LOG->is_trace()) {
        MediaManager::dump_tags_trace($image);
    }

    $self->{createDate} = undef;
    if($dateString) {
        $LOG->debug("got createDate [$dateString] for [$image].");

        my $t = undef;
        if ($dateString =~ m/^[0-9]{10}$/) {
            $LOG->debug("dateString is a timestamp");
            $t = &Util::convert_from_epoch($dateString + 0); # force to numeric
        } else {
            $t = &Util::parse_date($dateString, @dateformats);
        }

        if(&Util::is_before_now($t)) {
            # i.e.: create date is not in the future
            $self->{createDate} = $t;
        } else {
            # create date is in the future and needs adjustment
            $LOG->logdie("Got a createDate in future, assume camera had wrong date.");
        }
    } else {
        $LOG->debug("No createDate found in image [$image].");
    }
    return $self->{createDate};
}

sub copy_to_dest {
    my $self = shift;
    my $dest = shift;
    my %tags = %{ shift() };

    my $status = undef;
    
    if($dest ne $self->{destPath}) {
        $LOG->logdie("invalid state exception: dest_image [$dest] does not match destPath [$self->{destPath}]");
    }

    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($self->{srcPath});

    foreach my $key (keys(%tags) {
        ($success, $errmsg) = $exifTool->SetNewValue("$key" => $tags{$key});
        warn("unable to update tag [$key] on image [" . $self->{srcPath} . "] because [$errmsg]")
            unless $success;
    }

    $status = $exifTool->WriteInfo($srcfile, $dstfile);

    my $errorMessage = $exifTool->GetValue('Error');
    my $warningMessage = $exifTool->GetValue('Warning');
    if ($status > 0) {
        $LOG->debug("successfully copied to $dest");
        if($warningMessage) {
            $LOG->info("copy to $dest succeeded with warning: ".$warningMessage);
        }
    } else {
        $LOG->info("error occurred when writing $dest: ".$errorMessage)
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
    my $date = $created->ymd();
    my $year = $created->year();

    my $destdir = $docroot . '/' . $year . '/' . $date;

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

    my $date = $created->ymd('');
    my $time = $created->hms('');
    my $datetime = $date . 'T' . $time;

    my $name = $destdir . '/' . $datetime . '_' . sprintf('%02d', $serial) . $suffix;

    # cap recursion at 100 increments
    while($serial < 100 && -e $name) {
        $LOG->debug("recursing on [$name] since it exists.");
        $name = &make_filepath($destdir, $created, ++$serial, $suffix);
    }

    if($serial == 100) {
        $LOG->logdie("too many duplicate image filenames, unable to create new filename for [$name].");
    }

    return $name;
}

1;
