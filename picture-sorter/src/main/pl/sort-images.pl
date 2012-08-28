#!/usr/bin/perl

use strict;
use Image::ExifTool qw(:Public);
use File::Path;
use File::Copy;
use constant WD => '/Users/ebridges/Documents/Projects/photo-utils/picture-sorter';
use constant DEST => 'target/';

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
    # TODO
    # extract created date from EXIF data of image and format as yyyy-mm-dd
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
    $exifTool−>ExtractInfo($img);
    for my $tag (@tags){
	my $val = $exifTool->GetValue($tag);
	$val = &trim($val);
	return $val
	    if $val;
    }
    return undef;
}

sub trim {
    my $v = shift;
    $v =~ s/^\s+//g;
    $v =~ s/\s+$//g;
    return length($v) > 0 ? $v : undef;
}
