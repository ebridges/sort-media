package File;

use base 'Manifest';
use strict;
use warnings;

use constant IPUT => 'incoming.mf';
use constant OPUT => 'outgoing.mf';
use constant EPUT => 'errors.mf';


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
    return $root . '/' . IPUT ;
}

sub outputfile {
    my $self = shift;
    my $root = $self->{manifest_uri};
    return $root . '/' . OPUT ;
}

sub errorfile {
    my $self = shift;
    my $root = $self->{manifest_uri};
    return $root . '/' . EPUT ;
}

sub read {
    my $self = shift;
    my $file = $self->inputfile();
    open FILE, $file 
	or $LOG->logdie("unable to open $file: $!");
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
    
    my $ecnt = 0;
    $ecnt = $self->_write($efile, @{$self->{'unsuccessful'}})
	if($self->cnt_unsuccessful() > 0);

    my $ocnt = 0;
    $ocnt = $self->_write($ofile, @{$self->{'successful'}})
	if($self->cnt_successful() > 0);
    
    # scalar context gives size of array
    my $icnt = $self->{inputfiles};
    
    $LOG->trace("$ocnt + $ecnt == $icnt");
    if($icnt == ($ocnt + $ecnt)) {
	$self->_truncate($ifile);
    } else {
        $LOG->logwarn("warning: not all input files were processed.");
    }
}

sub _truncate {
    my $self = shift;
    my $file = shift;
    open FILE, ">$file"
	or $LOG->logdie("unable to truncate $file: $!");
    close FILE;
}

sub _write {
    my $self = shift;
    my $file = shift;
    my @list = @_;
    my $i = 0;

    my $mode;

    if( -e $file ) {
	$mode = '>>';
    } else {
	$mode = '>';
    }

    open FILE, "$mode$file" 
	or $LOG->logdie("unable to open $file in mode ($mode): $!");
    for(@list) {
	$LOG->trace("writing $_ to $file");
	print FILE $_ . "\n";
	$i++
    }
    close FILE;
    $i;
}
