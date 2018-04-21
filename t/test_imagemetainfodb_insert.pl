use strict;
use warnings;

require './t/test_util.pl';

our $LOG = get_logger();

use ImageMetaInfoDB qw(new save_image_info);

my $testdb = &reset_test_db();
my $db = new ImageMetaInfoDB($testdb);

my $file_01 = new MockMediaFile(
  'blah/blah/blah.jpg',
  'asdf-asdf-asdf-asdf',
  '2000-01-01T00:00:00Z',
  'uiop-uiop-uiop-uiop',
  'photos'
);
$db->save_image_info($file_01);
assert_save(&testdbfile(), $file_01);

