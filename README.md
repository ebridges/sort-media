# sort-media

Perl script to sync images & videos from Dropbox, extract the date of creation, and rename the media file in a centralized location.

It uses [rclone](http://rclone.org/) to synchronize the files from the `Camera Uploads` folder in a Dropbox account.

It is designed to operate under the constraints of a resource-limited NAS, where only Perl is available by default.

The program tries a [variety of create-date tags](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L25) in a specific order, falling back to the last modification date of the file if none of the others are found.

Each copied file is named according to this pattern:
`${copy-destination}/yyyy-MM-DD/yyyyMMDDTHHmmss_nn.typ`

(`nn` is a serial number that is there to avoid duplicate name clashes.  [See here for details](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L165)).

## Setup

Before this can be used, `rclone` must be [authorized to work with a Dropbox account](http://rclone.org/dropbox/):

```
$ rclone config
```

## Usage

To run the script execute it with the name of the account configured above:

```
$ ./sbin/sync-photos.pl ebridges
```

## Configuration

* Managed in file `etc/config.ini`

* Configuration Parameters
<dl>
<dt>logging-config</dt>
<dd>Location of log4perl configuration file.</dd>
<dt>local-directory</dt>
<dd>Location where remote files will be sync'd to.</dd>
<dt>remote-directory</dt>
<dd>Remote location where files will be sync'd from.</dd>
<dt>copy-image-destination</dt>
<dd>Location where images are copied to.</dd>
<dt>copy-video-destination</dt>
<dd>Location where videos are copied to.</dd>
<dt>includes-file</dt>
<dd>Filename extensions of files that should be copied from the remote-directory.</dd>
<dt>rclone-bath</dt>
<dd>Path (either relative or absolute> to the `rclone` binary.</dd>
<dt>remove-remote-files</dt>
<dd>Remove remote files after successfully processing</dd>
<dt>purge-local-dir</dt>
<dd>Clean up local sync dir after running.</dd>
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
<dd>Specifies the section of the config to pull from -- either `DEVELOPMENT` (default if absent) or `PRODUCTION`</dd>
</dl>

## To Do

* Add support for copying videos that have an associated THM metadata file.
* Remove functionality [here](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L115) which adjusts photos taken during an extended period of time where our camera had the wrong date.
