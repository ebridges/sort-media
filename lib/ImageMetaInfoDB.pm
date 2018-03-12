package ImageMetaInfoDB;

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use DBI;
use DBD::CSV;

use constant IMAGE_INFO_TABLE => 'media_info';
use constant IMAGE_INFO_DB_EXT => '.csv';

our $LOG = get_logger();

sub new {
    my $class = shift;
    my $database = shift;

    my $dbfile = $database . '/' . IMAGE_INFO_TABLE . IMAGE_INFO_DB_EXT;
    if(not -e "$dbfile") {
        $LOG->logdie("database file not found at: $dbfile");
    }

    $LOG->debug("using $dbfile as image info database.");

    my $dbh = DBI->connect ('dbi:CSV:', undef, undef, {
        f_dir => $database,
        f_ext      => IMAGE_INFO_DB_EXT,
        f_encoding => 'utf8',
        RaiseError => 1,
    }) or die "Cannot connect: $DBI::errstr";

    my $self = {
        dbh => $dbh
    };

    bless $self, $class;
    return $self;
}

sub save_image_info {
    my $self = shift;
    my $image = shift;

    my $isodate = $image->{createDate}->iso8601();
    my $csum = substr($image->{checkSum}, 0, 10);

    $LOG->debug("Saving image info: $image->{imageUri}/$image->{uuid}/$isodate/$csum...");

    $self->{dbh}->do(
        "insert into ".IMAGE_INFO_TABLE." values (?, ?, ?, ?)",
        undef,
        $image->{imageUri},
        $image->{uuid},
        $isodate,
        $image->{checkSum}
    );
}

1;
