# sort-media

Perl script to sort images into a central folder location.

Starting with a heap of unsorted images with proper EXIF creation date tags, it copies the files to a specified location sorted into folders named with the creation date. Each file is named according to this pattern:

`${copy-destination}/yyyy-MM-DD/yyyyMMDDTHHmmss_nn.typ`

(`nn` is a serial number that is there to avoid duplicate name clashes.  [See here for details](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L173)).

## Usage

  ```bash
  $ find <srcdir> -iname '*.jpg' -o -iname '*.jpeg' | sort-media.pl
  ```
    
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
* Remove functionality [here](https://github.com/ebridges/sort-media/blob/master/lib/MediaFile.pm#L90) which adjusts photos taken during an extended period of time where our camera had the wrong date.

