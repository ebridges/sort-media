package MediaManager;

use strict;
use warnings;

use Image::ExifTool qw(:Public);
use Log::Log4perl qw(get_logger);

our $LOG = get_logger();

sub resolve_tags {
    my $img = shift;
    my @tags = @_;
    $LOG->debug("resolve_tags('$img') called.");
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($img);
    for my $tag (@tags){
	my $value = $exifTool->GetValue($tag);
	my $val = &Util::trim($value);
	if($val) {
	    $LOG->info("tag [$tag] resolved to [$val]");
	    return $val;
	} else {
	    $LOG->debug("no value found for tag [$tag]");
	}
    }
    return undef;
}

sub update_tags {
    my $img = shift;
    my $value = shift;
    my $val = $value->datetime; # iso8601 format
    my @tags = @_;
    $LOG->debug("update_tags('$img') called.");
    my $exifTool = new Image::ExifTool;
    $exifTool->ExtractInfo($img);
    for my $tag (@tags){
	my $errmsg;
	my $success;
	$LOG->debug("setting tag [$tag] to value [$val] on [$img]");
	($success, $errmsg) = $exifTool->SetNewValue("$tag", $val);
	$LOG->warn("unable to update tag [$tag] on image [$img] because [$errmsg]")
	    unless $success;
    }
    $exifTool->WriteInfo($img);
    return 1;
}

1;
