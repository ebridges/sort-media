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
use constant CAMERA_DATE => '2034-04-30T16:14:00'; # 2030040840
use constant CURRENT_DATE => '2012-09-04T23:20:00'; # 1346815200

our $LOG = get_logger();


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
    my ($filename, $directories, $suffix) = fileparse($self->{srcPath}, qr/\.[^.]*/);
    $self->{srcFilename} = $filename;
    $self->{srcSuffix} = $suffix;
    $self->{hasAdjustment} = undef;
    $self->{mediaType} = &Util::type($self->{srcPath});
    bless $self, $class;
    return $self;
}

sub validate {
    my $self = shift;
    my $type = &Util::type($self->{srcPath});
    if($type) {
        return 1;
    } else {
        return undef;
    }
}

# Returns a DateTime object representing the creation date of the image.
sub create_date {
    my $self = shift;
    $LOG->trace('create_date() called for: ' . $self->{srcPath});
    # extract created date from EXIF data of image and format as ISO-8601 format
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

        if (not $t) {
            warn("Unable to parse DateTime from [$dateString].");
            return undef;
        }

        if(&Util::is_before_now($t)) {
            # i.e.: create date is not in the future
            $self->{createDate} = $t;
        } else {
            # create date is in the future and needs adjustment
            $LOG->logdie("Got a createDate in future, assume camera had wrong date.");
        }

        $self->{createDate_iso8601} = $self->{createDate}->iso8601();
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

    for my $key (keys(%tags)) {
        my ($success, $errmsg) = $exifTool->SetNewValue("$key" => $tags{$key});
        warn("unable to update tag [$key] on image [" . $self->{srcPath} . "] because [$errmsg]")
            unless $success;
    }

    # add a UUID based on filename as ImageUniqueID
    my $uuid = &Util::calc_uuid($dest);
    $self->{uuid} = $uuid;
    $exifTool->SetNewValue("imageuniqueid", $uuid);

    $status = $exifTool->WriteInfo($self->{srcPath}, $dest);

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

    $self->{checkSum} = &Util::calc_checksum($dest);

    return $status;
}

## format filepath as $destdir/yyyy-mm-dd/yyyymmdd_hhmmss_nnn.typ
sub format_dest_filepath {
    $LOG->trace('format_dest_filepath() called.');
    # format the filename for the new image as yyyymmdd_hhmmss_nnn.typ where
    # 'nnn' is a serial number incremented if the image exists already, or just '001'
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
    $self->{imageUri} = $year . '/' . $date . '/' . &basename($self->{destPath});

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

    my $name = $destdir . '/' . $datetime . '_' . sprintf('%03d', $serial) . $suffix;

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
