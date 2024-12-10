package Storm;
use strict;
use warnings;
use Exporter 'import';
use LWP::UserAgent;
use Archive::Zip;
use XML::LibXML;
use Globals qw($stormsettings);  # Import storm settings from Globals

our @EXPORT_OK = qw(fetch_and_process_storms);

# Fetch, parse, and process storms
sub fetch_and_process_storms {
    my $storm_list_url = 'https://www.nrlmry.navy.mil/atcf_web/docs/current_storms/stormlist.current';

    # Step 1: Fetch and parse the storm list
    my $storms = parse_storm_list($storm_list_url);
    print "Debug: Parsed Storms: @$storms\n";

    # Step 2: Process each storm
    foreach my $designator (@$storms) {
        my $kmz_url = construct_kmz_url($designator);
        print "Debug: KMZ URL for $designator: $kmz_url\n" if defined $kmz_url;

        # Fetch and parse KMZ if the URL exists
        if ($kmz_url) {
            print "Processing $designator...\n";
            my $storm_data = download_and_parse_kmz($kmz_url, '/path/to/output/dir');

            # Example: Output historical track
            foreach my $point (@$storm_data) {
                print "Historical Track: $point->{coordinates} at $point->{timestamp}\n";
            }
        }
    }
}

# Parse the storm list 
sub parse_storm_list {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new;

    # Point to the certificate file
    $ENV{PERL_LWP_SSL_CA_FILE} = 'C:\Users\mcoblent\.ssh\pems\cacert.pem';  # Update with your actual path

    my $response = $ua->get($url);

    die "Failed to fetch storm list: " . $response->status_line unless $response->is_success;

    print "Debug: Successfully downloaded storm list from $url\n";

    my @storms;
    foreach my $line (split "\n", $response->decoded_content) {
        if ($line =~ /\b([a-z]{2}\d{2}\d{4})\b/i) {  # Match designators
            push @storms, $1;
        }
    }

    return \@storms;  # Return a reference to the list of storm designators
}

# Map designators to KMZ URLs
sub construct_kmz_url {
    my ($designator) = @_;
    my ($basin, $storm_number, $year) = $designator =~ /([a-z]{2})(\d{2})(\d{4})/i;

    # Determine source and construct the URL
    if ($basin =~ /^(AL|EP|CP)$/i) {  # NHC/CPHC basins
        return "https://www.nhc.noaa.gov/storm_graphics/api/${designator}_TRACK_latest.kmz";
    } elsif ($basin =~ /^(WP|IO|SH|AU)$/i) {  # JTWC basins
        my $abbreviated_year = substr($year, -2);  # Abbreviated year for JTWC
        return "https://www.metoc.navy.mil/jtwc/products/${basin}${storm_number}${abbreviated_year}.kmz";
    }

    print "Warning: No matching source for $designator\n";
    return undef;  # Undefined if no matching source
}

# Download and parse a KMZ file
sub download_and_parse_kmz {
    my ($kmz_url, $output_dir) = @_;
    my $ua = LWP::UserAgent->new;

    # Download the KMZ file
    my $response = $ua->get($kmz_url, ':content_file' => "$output_dir/temp.kmz");
    unless ($response->is_success) {
        warn "Failed to fetch KMZ from $kmz_url: " . $response->status_line;
        return;
    }

    print "Debug: Successfully downloaded KMZ from $kmz_url\n";

    # Extract and parse the KML file
    my $zip = Archive::Zip->new("$output_dir/temp.kmz");
    my $kml_content = $zip->contents('doc.kml');
    die "Failed to extract doc.kml from KMZ file" unless defined $kml_content;

    my $parser = XML::LibXML->new();
    my $doc = $parser->load_xml(string => $kml_content);

    # Extract and print storm data
    my @data_points;
    foreach my $placemark ($doc->findnodes('//Placemark')) {
        my $timestamp = $placemark->findvalue('.//TimeStamp/when');
        my $coordinates = $placemark->findvalue('.//Point/coordinates');
        push @data_points, { timestamp => $timestamp, coordinates => $coordinates };
        print "Debug: Timestamp: $timestamp, Coordinates: $coordinates\n";
    }

    return \@data_points;  # Return parsed storm data
}

1;  # End of module
