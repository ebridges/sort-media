# Permissions Setup

## Shared Group
* In order to exchange information, the group `watched` is shared 
  between the `imgsorter` user and client users.

## Image Manifests
* All folders & manifest files should be group owned by `watched`
  and group writable.  User ownership is not important.

		$ ls -l /var/local/db/sort-media
		drwxrwsr-x 2 joeuser watched 4096 2012-09-24 23:11 joeuser
		
		$ ls -l /var/local/db/sort-media/joeuser:
		-rw-rw-r-- 1 imgsorter watched 0 2012-10-23 06:35 errors.mf
		-rw-rw-r-- 1 joeuser  watched 0 2012-10-23 00:15 incoming.mf
		-rw-rw-r-- 1 imgsorter watched 0 2012-10-23 00:30 outgoing.mf

## Home Directories
* Must be group or world `r-x` to allow for reading of EXIF tags
* Home directory is left at `0750` with group owned by `watched`
  to avoid members of `watched` being able to browse home directories.

		$ ls -l /home
		drwxr-x--- 9 joeuser watched 4096 2012-10-16 06:43 joeuser

* Everything under the home directory left at `0755` to avoid
  needing to maintain special permissions.
  
		$ ls -l /home/joeuser/Dropbox
		drwxr-xr-x  2 joeuser users 4096 2012-10-23 06:35 Camera Uploads
or, if leaving it at `0755` is unacceptable:

		$ ls -l /home/joeuser/Dropbox
		drwxr-x---  2 joeuser watched 4096 2012-10-23 06:35 Camera Uploads
