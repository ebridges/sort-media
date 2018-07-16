#!/usr/bin/env perl

use strict;
use warnings;

use Config::IniFiles;
use Log::Log4perl qw(get_logger);

use ImageMetaInfoDB;
use UploadClient;

my $params_file=shift;
die_usage()
    unless $params_file;

die "Parameter file not found at [$params_file]"
    unless -e $params_file;

my $env = 'DEVELOPMENT';
if (defined $ENV{IMGSORTER_ENV}) {
    $env = $ENV{IMGSORTER_ENV};
}

my $ini_file = 'etc/config.ini';
tie my %cfg, 'Config::IniFiles', ( -file => $ini_file );
my %config = %{$cfg{$env}};

Log::Log4perl->init($config{'logging-config'});
my $LOG = get_logger();
my $db = new ImageMetaInfoDB($config{'image-database'});

tie my %ini, 'Config::IniFiles', ( -file => $params_file );
my %params = %{$ini{$env}};
my $service = new UploadClient($db, %params);

my $result = $service->year_folder('2019/2019-02-01/abcdefg.jpg');
print("my result: " . $result);

die;

my $href = $db->query_by_workflow(ImageMetaInfoDB::SYNCHRONIZED);

for(keys(%{$href})) {
  chomp;
  my $album_url = &resolve_album($href->{$_}->{path});
}

sub resolve_album {
  my $c = shift;
  my $path = shift;
  $path =~ s/^\///; # strip leading slash if present
  my $folder_url = sprintf('/%s', &dirname($path));
  my %folder_info = $c->folder_info($folder_url);

}



sub die_usage {
    my $mesg = "Usage: $0 [upload-params]\n";
    die $mesg;
}
