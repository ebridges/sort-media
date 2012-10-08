#!/usr/bin/perl -w

use strict;
use warnings;

my $user = shift;

die "usage: $0 [username]\n"
    unless defined $user;

my $delete_manifest = '/var/local/db/sort-media/'.$user.'/outgoing.mf';

die "unable to locate list of files to delete at [$delete_manifest]: $!\n"
	unless -e $delete_manifest;

open F, $delete_manifest
    or die "unable to open delete manifest: $!\n";
my @files = <F>;
close F;

chomp @files;
my @not_ok;
for(@files) {
    next
	if(-d);
#    print "deleting file [$_]\n";

    my $ok = unlink;
    
    if(not $ok) {
	warn "unable to delete [$_]: $!\n";
	push @not_ok, $_;
    } 
}

open F, ">$delete_manifest"
    or die "unable to truncate deletion manifest [$delete_manifest]: $!\n";
if(scalar @not_ok) {
    for(@not_ok){
	print F "NOK\t$_\n";
    }
}
close F;
