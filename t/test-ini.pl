#!/usr/bin/perl -w

use strict;
use warnings;

use Config::IniFiles;

my $env = $ENV{IMGSORTER_ENV};
my $ini = '../etc/config.ini';
my $cfg = Config::IniFiles->new( 
    -file => $ini,
    -default => 'Default'
    );

my $COPY_ENABLED = $cfg->val( $env, 'copy-enabled' );
my $REMOVE_ORIGINAL = $cfg->val( $env, 'remove-original' );
my $WORKING_DIR = $cfg->val( $env, 'working-directory' );
my $COPY_DESTINATION = $cfg->val( $env, 'copy-destination' );
my $LOGGING_CONFIG = $cfg->val( $env, 'logging-config' );

print "copy-enabled: " .  $COPY_ENABLED . "\n";
print "remove-original: " . $REMOVE_ORIGINAL . "\n";
print "working-directory: " . $WORKING_DIR . "\n";
print "copy-destination: " . $COPY_DESTINATION . "\n";
print "logging-config: " . $LOGGING_CONFIG . "\n";

if($REMOVE_ORIGINAL) {
    print $REMOVE_ORIGINAL . "\n";
}
