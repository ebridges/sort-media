# sort-media

Perl script to copy and sort images into a central folder location from a variety of source folders, and to then mark the originals for deletion.  It only requires read access to the originals and will log all files that can be safely deleted, so that a separate process can later delete them.  This way, different user accounts can each setup a cron job that will push out files to be processed, and then sort-media will attempt to sort them and provide notification via log file that the processing was successful or not.

Starting with a heap of unsorted images with proper EXIF creation date tags, it copies the files to a specified location sorted into folders named with the creation date. The program tries a [variety of create-date tags](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L25) in a specific order, falling back to the last modification date of the file if none of the others are found. 

Each copied file is named according to this pattern:
`${copy-destination}/yyyy-MM-DD/yyyyMMDDTHHmmss_nn.typ`

(`nn` is a serial number that is there to avoid duplicate name clashes.  [See here for details](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L173)).

## Usage

<table border=“0”>
<tr>
<td>User account</td>
<td>Command</td>
</tr>
<tr>
<td><tt>joeuser</tt></td>
<td>
<pre>[joeuser@localhost]$ gather-media.pl \
	joeuser \
        ~/Dropbox/CameraUploads \
        ~/Pictures \
        ~/Dropbox/Photos</pre>
</td>
</tr>
<tr>
<td><tt>imgsorter</tt></td>
<td>
<pre>[imgsorter@localhost]$ sort-media.pl joeuser </pre>
</td>
</tr>
<tr>
<td><tt>joeuser</tt></td>
<td>
<pre>[joeuser@localhost]$ remove-media.pl joeuser </pre>
</td>
</tr>
</table>

## Configuration

* Managed in file `etc/config.ini`

* Parameters
<dl>
<dt>logging-config</dt>
<dd>Location of log4perl configuration file.</dd>
<dt>remove-original</dt>
<dd>Remove the file from the source location after successful copy.</dd>
<dt>copy-enabled</dt>
<dd>Disable the copy (and removal) altogether.</dd>
<dt>working-directory</dt>
<dd>The directory that commands are run from. Used for logging config/logfile. Useful if relative destination paths are desired.</dd>
<dt>copy-destination</dt>
<dd>The location where files are copied to.</dd>
</dl>

## Environment

* Specified in file `profile`

* Variables
<dl>
<dt>PERL5LIB</dt>
<dd>Specifies where the scripts modules are.</dd>
<dt>PATH</dt>
<dd>Appends the bin folder to the executable path.</dd>
<dt>IMGSORTER_ENV</dt>
<dd>Specifies the section of the config to pull from -- either `DEVELOPMENT` or `PRODUCTION`</dd>
</dl>

## To Do

* Add support for copying videos that have an associated THM metadata file.
* Remove functionality [here](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L95) which adjusts photos taken during an extended period of time where our camera had the wrong date.
* Change `sort-media.pl` to accept multiple usernames.
* <del>Change to log deleted files to a flatfile, that can be read by another process to do the physical delete.</del>
