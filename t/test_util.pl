use Test::Assertions qw(test);

use Log::Log4perl qw(get_logger);
Log::Log4perl->init('./t/test_log4perl.conf');

use constant TEST_DATABASE => '/var/tmp/imagemetainfodb.pl';

sub testdbfile {
  return TEST_DATABASE . '/' . ImageMetaInfoDB::IMAGE_INFO_TABLE . ImageMetaInfoDB::IMAGE_INFO_DB_EXT;
}

sub reset_test_db {
  my $testdbfile = &testdbfile();
  &reset_data_file($testdbfile);
  return TEST_DATABASE;
}

sub assert_save {
  my $file = shift;
  my $data = shift;
  my $uuid = $data->{uuid};
  my $expected = &data_to_line($data);

  open my $fh, '<:encoding(UTF-8)', $file or die "$0: $file: No such file\n";
  while (my $actual = <$fh>) {
    if ($actual =~ /$uuid/) {
      $LOG->trace("\n[E] $expected\[A] $actual");
      ASSERT(EQUAL($actual, $expected));
      return;
    }
  }  
}

sub cmp_strings {
  my $string1 = shift;
  my $string2 = shift;
  my $result = '';
  for(0 .. length($string1)-1) {
      my $char = substr($string2, $_, 1);
      if($char ne substr($string1, $_, 1)) {
          $result .= "**$char**";
      } else {
          $result .= $char;
      }
  }
  print $result . "\n";  
}

sub cols {
  return sprintf("%s,%s,%s,%s,%s,%s\r\n", ImageMetaInfoDB::DB_COLUMNS);
}

sub data_to_line {
  my $d = shift;
  my $workflow = shift || ImageMetaInfoDB::SYNCHRONIZED;
  return sprintf("%s,%s,%s,%s,%s,%s\r\n",
    $d->{imageUri},
    $d->{uuid},
    $d->{createDate_iso8601},
    $d->{checkSum},
    $d->{mediaType},
    $workflow
  );
}

sub reset_data_file {
  my $file = shift;
  local(*TMP);
  open(TMP, ">$file")
    or die("Can't reset datafile: $file: $!\n");
  print TMP &cols();
  close TMP;
}


package MockMediaFile;

sub new {
  my $class = shift;
  my $self = {
    imageUri => shift,
    uuid => shift,
    createDate_iso8601 => shift,
    checkSum => shift,
    mediaType => shift
  };
  bless $self, $class;
  return $self;
}

1;
