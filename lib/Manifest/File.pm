package File;

use base 'Manifest';
use strict;
use warnings;

use constant IPUT => 'input';
use constant OPUT => 'output';
use constant EPUT => 'errors';
use constant DBFILE => 'manifest.txt';

use Log::Log4perl qw(get_logger);

our $LOG = get_logger();

sub new {
    my $class = shift;
    my @params = @_;
    $class->SUPER::new(@params);
    ## also... SUPER::new(@_);
}

sub inputfile {
    my $self = shift;
    my $root = $self->{manifest_uri};
    return $root . '/' . IPUT . '/' . DBFILE;
}

sub outputfile {
    my $self = shift;
    my $root = $self->{manifest_uri};
    return $root . '/' . OPUT . '/' . DBFILE;
}

sub errorfile {
    my $self = shift;
    my $root = $self->{manifest_uri};
    return $root . '/' . EPUT . '/' . DBFILE;
}

sub read {
    my $self = shift;
    my $file = $self->inputfile();
    open FILE, $file or $LOG->logdie("unable to open $file: $!");
    my @files = <FILE>;
    close FILE;
    chomp @files;
    $self->{inputfiles} = @files;
    return \@files;
}

sub write {
    my $self = shift;
    my $ofile = $self->outputfile();
    my $efile = $self->errorfile();
    my $ifile = $self->inputfile();
    my $ecnt = $self->_write($efile, @{$self->{'unsuccessful'}});
    my $ocnt = $self->_write($ofile, @{$self->{'successful'}});
    
    # scalar context gives size of array
    my $icnt = $self->{inputfiles};
    
    $LOG->trace("$ocnt + $ecnt == $icnt");
    if($icnt == ($ocnt + $ecnt)) {
	my $err = $self->_truncate($ifile);
    } else {
        $LOG->logwarn("warning: not all input files were processed.");
    }
}

sub _truncate {
    my $self = shift;
    my $file = shift;
    return $self->_write($file);
}

sub _write {
    my $self = shift;
    my $file = shift;
    my @list = @_;
    my $i = 0;
    open FILE, ">$file" or $LOG->logdie("unable to truncate $file: $!");
    for(@list) {
	$LOG->trace("writing $_ to $file");
	print FILE $_ . "\n";
	$i++
    }
    close FILE;
    $i;
}
