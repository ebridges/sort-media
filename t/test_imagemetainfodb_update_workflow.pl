use strict;
use warnings;

require './t/test_util.pl';

our $LOG = get_logger();

use ImageMetaInfoDB qw(new save_image_info);

my $testdb = &reset_test_db();
my $db = new ImageMetaInfoDB($testdb);

my $mock_id = 'asdf-asdf-asdf-asdf';
my $file_01 = new MockMediaFile(
  'blah/blah/blah.jpg',
  $mock_id,
  '2000-01-01T00:00:00Z',
  'uiop-uiop-uiop-uiop',
  'photos'
);
$db->save_image_info($file_01);
assert_save(&testdbfile(), $file_01);

$db->update_workflow($mock_id, ImageMetaInfoDB::UPLOADED);
my $expected = &expected_file_contents($file_01, ImageMetaInfoDB::UPLOADED);

$LOG->trace("\n[E] $expected");
ASSERT(MATCHES_FILE($expected, &testdbfile()));

sub expected_file_contents {
  my $d = shift;
  my $workflow = shift;
  return sprintf("%s%s", 
    &cols(),
    &data_to_line($d, $workflow)
  );
}
