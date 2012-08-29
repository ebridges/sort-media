#!/usr/bin/perl

use strict;
use warnings;
use Image::ExifTool qw(:Public);
use File::Path;
use File::Copy;
use constant WD => '/Users/ebridges/Documents/Projects/photo-utils/picture-sorter';
use constant DEST => 'target/';

my @created_tags = q(
'CreateDate',
'datecreate',
'CreateDate (1)',
'DateTimeDigitized',
'DateTimeOriginal',
'DateTimeOriginal (1)'
);

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
while(<>) {
    ## image filename
    my $image = $_;

    ## extract create date of image, formatted as yyyy-mm-dd
    my $created = &create_date($image);

    my $dest_dir = DEST . '/' . $created;

    if(not -e $dest_dir) {
	die "unable to create dest dir ($dest_dir): $!\n" 
	    unless mkpath $dest_dir;
    }

    ## extract filename as $dest_dir/yyyy-mm-dd_hhmmss_#.typ
    my $dest_image = &format_dest_filename($dest_dir, $image);

    die "dest image already exists! ($dest_image) from ($image)"
	unless not -e $dest_image;

    die "error moving ($image) to ($dest_image): $!"
	unless move $image, $dest_image;
}

sub create_date {
    # extract created date from EXIF data of image and format as yyyy-mm-dd
    my $image = shift;
    my $createDate = &resolve_tags($image, @created_tags);
    return $createDate;
}

sub format_dest_filename {
    # TODO
    # format the filename for the new image as yyyy-mm-dd_hhmmss_n.typ where
    # 'n' is a serial number incremented if the image exists already, or just '1'
}

sub resolve_tags {
    my $img = shift;
    my @tags = @_;
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($img);
    for my $tag (@tags){
	my $val = $exifTool->GetValue($tag);
	$val = &trim($val);
	return 
	    format_date(
		$tag_dateformats{$tag}, 
		$val
	    )
	    if $val;
    }
    return undef;
}

sub format_date {
    my $fmt  = shift;
    my $date = shift;
    my $t = Time::Piece->strptime($date, $fmt);
    return $t->ymd;   
}

sub format_date_time {
    my $fmt = shift;
    my $date = shift;
    my $t = Time::Piece->strptime($date, $fmt);
    return sprintf("%s_%s", $t->ymd, $t->hms(''));
}

sub trim {
    my $v = shift;
    $v =~ s/^\s+//g;
    $v =~ s/\s+$//g;
    return length($v) > 0 ? $v : undef;
}
