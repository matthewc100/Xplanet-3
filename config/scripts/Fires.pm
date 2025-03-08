package Fires;

use strict;
use warnings;
use LWP::Simple;
use Text::CSV;

use File::stat;
use Globals qw(
    $DEBUG
    $xplanet_markers_dir
    %modules
    convert_to_epoch
);

# Function to download fire data
sub download_fire_data {
    my $url = $Globals::modules{'fires'}{'fire.data.url'};  # Fetch URL from %modules
    die "Fire data URL is not defined in settings" unless $url;

    my $marker_file_name = $Globals::modules{'fires'}{'fire.marker.file'} // 'firedataout';  # Default marker file name
    my $output_file = File::Spec->catfile($xplanet_markers_dir, "$marker_file_name.csv");
    print "Downloading fire data from $url to $output_file...\n";

    my $response = getstore($url, $output_file);
    if ($response != 200) {
        die "Failed to download fire data from $url: HTTP $response";
    }

    return $output_file;
}

# Function to process fire data
sub process_fire_data {
    my ($csv_file) = @_;
    my $csv = Text::CSV->new({ binary => 1 });
    open my $fh, '<', $csv_file or die "Cannot open $csv_file: $!";

    # Get parameters from %modules
    my $confidence_threshold = $Globals::modules{'fires'}{'confidence.threshold'} // 80;
    my $temp_min = $Globals::modules{'fires'}{'temp.min'} // 300;
    my $temp_max = $Globals::modules{'fires'}{'temp.max'} // 500;

    my @filtered_data;
    while (my $row = $csv->getline($fh)) {
        # Skip rows where the confidence column isn't numeric
        my ($lat, $lon, $temp, $confidence) = @$row[0, 1, 2, 8];
        next unless $confidence =~ /^\d+$/;  # Skip non-numeric rows
        next unless defined $confidence && $confidence >= $confidence_threshold;
        next unless defined $temp && $temp >= $temp_min && $temp <= $temp_max;

        push @filtered_data, {
            latitude  => $lat,
            longitude => $lon,
            temp      => $temp,
            color     => temp_to_color($temp, $temp_min, $temp_max),
        };
    }
    close $fh;

    return \@filtered_data;
}


# Function to map temperature to color
sub temp_to_color {
    my ($temp, $temp_min, $temp_max) = @_;
    my $slope = 255 / ($temp_max - $temp_min);
    my $color = int(255 - $slope * ($temp - $temp_min));
    return $color < 0 ? 0 : ($color > 255 ? 255 : $color);
}

# Function to generate marker file
sub generate_marker_file {
    my ($fire_data) = @_;  # Fire data to write to the marker file
    my $marker_file_name = $Globals::modules{'fires'}{'fire.marker.file'} // 'firedataout';  # Default file name
    my $output_file = File::Spec->catfile($xplanet_markers_dir, $marker_file_name);  # Full path to marker file

    # Open the marker file for writing
    open my $fh, '>', $output_file or die "Cannot write to $output_file: $!";

    # Use Label::file_header to write the header
    Label::file_header($marker_file_name, $fh);  # Pass the marker file name and filehandle

    # Write the fire data entries to the marker file
    foreach my $fire (@$fire_data) {
        print $fh join(
            " ",
            $fire->{latitude}, $fire->{longitude}, '""',
            "color={255,$fire->{color},0}", "symbolsize=1"
        ), "\n";
    }

    # Close the marker file
    close $fh;

    print "Fire marker file created: $output_file\n";  # Confirm successful creation
}

# Main function for Fires module
sub run {
    my $fire_marker_file = "$xplanet_markers_dir/firedataout";

    # 🔍 **Retrieve Fire.update_interval from `[LABELS]`**
    my $update_frequency = $modules{'labels'}{'Fire.update_interval'};

    # **Check if Fire.update_interval is missing or invalid**
    if (!defined $update_frequency || $update_frequency !~ /^\d+$/) {
        print "⚠️ Fires::run - Warning: Fire.update_interval not found or invalid in .ini! Using default: 43200 seconds (12h)\n";
        $update_frequency = 43200;  # Default to 12 hours
    }

    # Check last modified timestamp of fire marker file
    if (-e $fire_marker_file) {
        my $file_stat = stat($fire_marker_file);
        my $last_modified = $file_stat->mtime;

        # Get current time in epoch
        my $current_time = time();
        my $time_diff = $current_time - $last_modified;

        # Debugging: Print update check info
        print "Fires::run - Debug: Fire marker last updated at: " . scalar localtime($last_modified) . "\n" if $DEBUG;
        print "Fires::run - Debug: Update frequency set to: $update_frequency seconds\n" if $DEBUG;
        print "Fires::run - Debug: Time since last update: $time_diff seconds\n" if $DEBUG;

        if ($time_diff < $update_frequency) {
            print "Fires::run - Fire update skipped: Next update allowed in " . ($update_frequency - $time_diff) . " seconds.\n";
            return;  # **Skip updating fires**
        }
    } else {
        print "Fires::run - No existing fire marker file found. Proceeding with update...\n" if $DEBUG;
    }

    # **Proceed with normal fire update process**
    download_fire_data($fire_marker_file);
}
1;  # End of module
