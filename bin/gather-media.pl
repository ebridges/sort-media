#!/usr/bin/perl

use strict;
use warnings;

use File::Find ();

my $user = shift;
my @dirs = @ARGV;

my $output = "/var/local/db/sort-media/$user/incoming.mf";

die "usage: $0 [user] [dir1 dir2 ...]\n"
    unless (scalar @dirs) > 0;

use vars qw/*name *dir *prune/;
*name   = *File::Find::name;
*dir    = *File::Find::dir;
*prune  = *File::Find::prune;

sub wanted;

# Traverse desired filesystems
my $log;
open $log, ">>$output"
    or die "unable to open output file [$output]: $!\n";
File::Find::find({wanted => \&wanted}, @dirs);
close $log;
exit;

sub wanted {
    my ($dev,$ino,$mode,$nlink,$uid,$gid);

    (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
    (/^.*\.jpg\z/si
    ||
    /^.*\.jpeg\z/si)
    && print $log "$name\n";
}
