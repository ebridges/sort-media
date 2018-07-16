package UploadClient;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use Util;
use LWP::Authen::OAuth;
use JSON qw( decode_json );
use Data::Dumper;
use File::Basename qw(dirname);

our $LOG = get_logger();

use constant OAUTH_ORIGIN => 'https://secure.smugmug.com';
use constant REQUEST_TOKEN_URL => OAUTH_ORIGIN . '/services/oauth/1.0a/getRequestToken';
use constant ACCESS_TOKEN_URL => OAUTH_ORIGIN . '/services/oauth/1.0a/getAccessToken';
use constant AUTHORIZE_URL => OAUTH_ORIGIN . '/services/oauth/1.0a/authorize';
use constant API_ORIGIN => 'https://api.smugmug.com';

sub new {
  my $self = {};
  my $class = shift;
  my $database = shift;
  my %params = @_;

  $self->{consumer_key} = $params{client_key};

  $self->{ua} = new LWP::Authen::OAuth(
    oauth_consumer_secret => $params{client_secret}
  );

  $self->{ua}->{oauth_token} = $params{access_token};
  $self->{ua}->{oauth_token_secret} = $params{access_token_secret};

  $self->{ua}->default_header('Accept' => 'application/json');

  bless $self, $class;
  return $self;
}

sub format_url {
  my $self = shift;
  my $api_path = shift;
  return sprintf('%s%s?oauth_consumer_key=%s',
    API_ORIGIN,
    $api_path,
    $self->{consumer_key}
  );
}

sub user_info {
  my $self = shift;
  if(exists $self->{user_info}) {
    return $self->{user_info};
  }

  my $url = $self->format_url('/api/v2!authuser');
  my $r = $self->{ua}->get($url);
  if($r->is_error) {
    $LOG->error("error from server: ". $r->error_as_HTML);
  }
  my %result = %{decode_json( $r->content )};
  $self->{user_info} = $result{'Response'};
  return $self->{user_info};
}

sub node_url {
  my $self = shift;
  $self->user_info()
    unless exists $self->{user_info};
  return $self->{user_info}{User}{Uris}{Node}{Uri};
}

sub year_folder {
  my $self = shift;
  my $path = shift;
  $path =~ s/^\.//; # strip leading dot if present
  $path =~ s/^\///; # strip leading slash if present
  my @parts = split /\//, &dirname($path);
  if(scalar(@parts) != 2) {
    die("invalid folder: $path");
  }
  my $year_folder = '/' . $parts[0];
  $LOG->info("year_folder: $year_folder");
  return $self->get_or_create_node($year_folder);
}


sub get_or_create_node {
  my $self = shift;
  my $path = shift;
  my $node_url = shift || $self->node_url();
  my $url = $self->format_url(sprintf("%s!children", $node_url));
  $LOG->info("get url: $url");

  my $r = $self->{ua}->get($url);
  print($r->as_string."\n");
  my %info = %{decode_json($r->content)};
  my $node = undef;
  print("path: $path\n");
  for(@{$info{'Response'}{'Node'}}) {
    if($_->{UrlPath} eq $path) {
      $node = $_;
    }
  }
  if(not $node) {
    $LOG->info("no node found for path: $path");
    $node = $self->create_folder($path, $url);
  }
  return $node;
}

sub create_folder {
  my $self = shift;
  my $path = shift;
  my $node_url = shift;
  my $name = $path;
  $name =~ s/^\///;
  $LOG->info("creating folder: $name");

  $LOG->info("post url: $node_url");
  my $r = $self->{ua}->post($node_url, 
    [Type => 'Folder', Name => $name, 'UrlName' => $path, 'Privacy' => 'Private']
  );
  print($r->as_string."\n");
  my %result = %{decode_json($r->content)};
  Dumper(%result);
  return %result;
}

# sub node_children {
#   my $self = shift;
#   if(not exists $self->{node_children}) {
#     my $node_url = $self->node_url();
#     my $url = $self->format_url(sprintf("%s!children", $node_url));
#     my $r = $self->{ua}->get($url);
#     my %result = %{decode_json($r->content)};
#     Dumper(%result);
# #    my $self->{node_children} = ;
#   }

# #  return $self->{node_children};
# }

# sub node_for_folder_path {
#   my $self = shift;
#   my $path = shift;

#   $path =~ s/^\///; # strip leading slash if present
#   my @parts = split /\//, &dirname($path);
#   if(scalar(length(@parts)) != 2) {
#     die("invalid folder: $path");
#   }
#   my $year_folder = '/' . $parts[0];
#   my $date_folder = $year_folder . '/' . $parts[1];
#   my $year_folder_info = $self->fetch_node_info($year_folder);
#   unless($year_folder_info) {
#     my $year = $parts[0];
#     $year_folder_info = $self->create_folder($year_folder);
#   }

#   my date_folder_info = $year_folder_info


  
# }



# sub fetch_node_info {
#   my $self = shift;
#   my $folder = shift;
#   my $url = $self->format_url(sprintf("%s!children", $node_url));
#   my $r = $self->{ua}->get($url);
#   my %result = %{decode_json($r->content)};

# }


# sub folder_info {
#   my $self = shift;
#   my $folder_url = shift;
#   my @folders = $self->{node_children};
#   for(@folders) {
#     if($_->{UrlPath} eq $folder_url) {
#       return $_;
#     }
#   }
#   return undef;
# }
