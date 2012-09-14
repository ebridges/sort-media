sort-media
==========

Perl script to sort images into a central folder location.

Usage:

  `find <srcdir> -iname '*.jpg' -o -iname '*.jpeg' | sort-media.pl`
    
Configuration:

* Managed in file `etc/config.ini`
* Parameters:
<dl>
<dt>`logging-config`</dt>
<dd>Location of log4perl configuration file.</dd>
<dt>`remove-original`</dt>
<dd>Remove the file from the source location after successful copy.</dd>
<dt>`copy-enabled`</dt>
<dd>Disable the copy (and removal) altogether.</dd>
<dt>`working-directory`</dt>
<dd>The directory that commands are run from. Used for logging config/logfile. Useful if relative destination paths are desired.</dd>
<dt>`copy-destination`</dt>
<dd>The location where files are copied to.</dd>
</dl>


