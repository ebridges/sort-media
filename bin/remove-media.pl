#!/usr/bin/perl -w

use strict;
use warnings;

my $delete_manifest = shift;

if(not defined $delete_manifest) {
    $delete_manifest = '/var/local/db/sort-media/'.$ENV{USER}.'/outgoing.mf';
}

die "unable to locate list of files to delete at [$delete_manifest]: $!\n"
	unless -e $delete_manifest;

open F, $delete_manifest
    or die "unable to open delete manifest: $!\n";
my @files = <F>;
close F;

chomp @files;
for(@files) {
    next
	if(-d);
#    print "deleting file [$_]\n";
    warn "unable to delete [$_]: $!\n"
	unless unlink;
}
