#!/usr/bin/perl -w

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
Log::Log4perl->init('./t/test_log4perl.conf');
our $LOG = get_logger();

use Config::IniFiles;

my $env = $ENV{IMGSORTER_ENV};
my $ini = 'etc/config.ini';
my $cfg = Config::IniFiles->new( 
    -file => $ini,
    -default => 'Default'
    );

$LOG->trace("copy-image-destination: " . $cfg->val( $env, 'copy-image-destination' ));
$LOG->trace("copy-video-destination: " . $cfg->val( $env, 'copy-video-destination' ));
$LOG->trace("logging-config: " . $cfg->val( $env, 'logging-config' ));
$LOG->trace("local-directory: " . $cfg->val( $env, 'local-directory' ));
$LOG->trace("remote-directory: " . $cfg->val( $env, 'remote-directory' ));
$LOG->trace("includes-file: " . $cfg->val( $env, 'includes-file' ));
$LOG->trace("rclone-path: " . $cfg->val( $env, 'rclone-path' ));
