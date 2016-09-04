#!/usr/bin/perl -w

use strict;
use warnings;

use Config::IniFiles;

my $env = $ENV{IMGSORTER_ENV};
my $ini = 'etc/config.ini';
my $cfg = Config::IniFiles->new( 
    -file => $ini,
    -default => 'Default'
    );

print "copy-image-destination: " . $cfg->val( $env, 'copy-image-destination' ) . "\n";
print "copy-video-destination: " . $cfg->val( $env, 'copy-video-destination' ) . "\n";
print "logging-config: " . $cfg->val( $env, 'logging-config' ) . "\n";
print "local-directory: " . $cfg->val( $env, 'local-directory' ) . "\n";
print "remote-directory: " . $cfg->val( $env, 'remote-directory' ) . "\n";
print "includes-file: " . $cfg->val( $env, 'includes-file' ) . "\n";
print "rclone-path: " . $cfg->val( $env, 'rclone-path' ) . "\n";
