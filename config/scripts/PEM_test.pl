use LWP::UserAgent;

$ENV{HTTPS_DEBUG} = 1;

my $ua = LWP::UserAgent->new(
    ssl_opts => {
        SSL_ca_file => 'C:\\Users\\mcoblent\\Downloads\\cacert.pem',  # Use double backslashes for Windows  "C:\Users\mcoblent\Downloads\cacert.pem"
        verify_hostname => 1,  # Ensure hostname verification is enabled
    }
);

my $response = $ua->get('https://www.nrlmry.navy.mil');

if ($response->is_success) {
    print "Success: " . $response->decoded_content . "\n";
} else {
    print "Error: " . $response->status_line . "\n";
}
