#!/usr/bin/env perl

use strict;
use warnings;

use ImageMetaInfoDB qw(new save_image_info);
use Util;

use Log::Log4perl qw(get_logger);
Log::Log4perl->init('etc/log4perl.conf');
our $LOG = get_logger();

my $db = new ImageMetaInfoDB('./db');

for(<>) {
    chomp;
    s/^\.\///;
    my ($file,$uuid,$date,$sum) = split /,/;
    my $type = &Util::type($file);
    die("unable to determine type from $file")
      unless $type;

    my $mediafile = new MigratedMediaFile(
      $file, $uuid, $date, $sum, $type
    );

    $LOG->info("saving $file as $type");
    $db->save_image_info($mediafile);
}

package MigratedMediaFile;

sub new {
  my $class = shift;
  my $self = {
    imageUri => shift,
    uuid => shift,
    createDate_iso8601 => shift,
    checkSum => shift,
    mediaType => shift
  };
  bless $self, $class;
  return $self;
}

1;
