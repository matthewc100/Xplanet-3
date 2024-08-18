package CloudUpdate;
use strict;
use warnings;
use Exporter 'import';
use LWP::UserAgent;
use HTTP::Request::Common;

our @EXPORT_OK = qw(cloud_update);

sub cloud_update {
    my ($url, $username, $password, $file_path, $xplanet_images_dir) = @_;

    # Ensure credentials are set
    die "Username and password must be provided" unless $username && $password;

    # Create a user agent object
    my $ua = LWP::UserAgent->new;

    # Create an HTTP request with basic authentication
    my $request = GET $url;
    $request->authorization_basic($username, $password);

    # Perform the request
    my $response = $ua->request($request);

    # Check if the request was successful
    if ($response->is_success) {
        # Open the file for writing in binary mode
        open my $fh, '>:raw', "$xplanet_images_dir/$file_path" or die "Could not open file '$xplanet_images_dir/$file_path': $!";
        print $fh $response->content; # Use content instead of decoded_content for binary data
        close $fh;
#        print "File downloaded successfully to $xplanet_images_dir as $file_path\n";
        print "  Updated cloud image\n";
    } else {
        die "Failed to download file: " . $response->status_line;
    }
}

1; # End of the module
