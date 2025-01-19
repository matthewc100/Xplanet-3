# Norad.pm
package Norad;
use strict;
use warnings;
use Exporter 'import';

use Globals qw(
    %modules
    $xplanet_satellites_dir
    $xplanet_images_dir
    get_webpage

    $noradsettings 
    $iss_file
    $isstle_file
);

our @EXPORT_OK = qw(
    process_satellites
);

## NORAD SITES
# ISS = International Space Station
# CSS = Chinese Space Station
# HST = Hubble Space Telescope

# Subroutine to parse satellite configuration file for NORAD IDs
sub parse_satellite_file {
    my ($file_path) = @_;
    my %satellite_ids;

    open my $fh, '<', $file_path or die "Could not open satellite file '$file_path': $!";
    while (my $line = <$fh>) {
        chomp $line;
        next if $line =~ /^\s*$/ || $line =~ /^#/;  # Skip empty lines and comments

        if ($line =~ /^(\d+)/) {  # Match the NORAD ID at the beginning of the line
            my $sat_id = $1;
            $satellite_ids{$sat_id} = 1;  # Store the satellite ID
        }
    }
    close $fh;

    return keys %satellite_ids;  # Return unique satellite IDs
}

# Helper function to get NORAD IDs from NoradTleNumbers setting
sub get_tle_numbers_from_settings {
    my $tle_numbers = $noradsettings->{NoradTleNumbers} // '';
    my @ids = split /[,\s]+/, $tle_numbers;  # Split by commas or whitespace
    return grep { $_ =~ /^\d+$/ } @ids;  # Return only numeric IDs
}


sub fetch_and_save_tle_data {
    # Subroutine to retrieve TLE data for each specific NORAD ID and output to a .TLE file with header
    my ($satellite_ids, $output_file) = @_;
    my $url_base = "https://www.celestrak.com/NORAD/elements/";

    # Open output file for writing the TLE data
    open my $out_fh, '>', $output_file or die "Could not open TLE output file '$output_file': $!";

    # Add file header using Label::file_header subroutine
    Label::file_header($output_file, $out_fh);

    foreach my $sat_id (@$satellite_ids) {
        # Construct the specific TLE URL for each satellite ID
        my $tle_url = $url_base . "gp.php?CATNR=$sat_id";

        # Attempt to fetch the TLE data
        my $tle_data = get_webpage($tle_url);

        if ($tle_data eq 'FAILED') {
            warn "Failed to retrieve TLE data for satellite $sat_id from $tle_url";
            next;
        }

        # Process each line of TLE data to control line feeds
        my @tle_lines = split("\n", $tle_data);
        
        # Filter out blank lines and trim extra whitespace
        @tle_lines = map { s/^\s+|\s+$//gr } grep { /\S/ } @tle_lines;

        # Write the formatted TLE data to the output file, ensuring a single newline between entries
        print $out_fh join("\n", @tle_lines) . "\n";
    }
    close $out_fh;

    # Message indicating successful update of the TLE file
    print "NORAD TLE file successfully updated: $output_file\n";
}

# Main function to read satellite file, fetch TLE data, and generate marker file with settings from .ini file
sub process_satellites {
    my ($satellite_file, $output_tle_file, $marker_file) = @_;

    # Step 1: Get NORAD IDs from settings or satellite file
    my @satellite_ids = get_tle_numbers_from_settings();
    my @file_satellite_ids = parse_satellite_file($satellite_file) unless @satellite_ids;
    
    # Conflict checking for ISS and HST NORAD numbers
    if (grep { $_ == 25544 } @file_satellite_ids && $Globals::modules{'norad'}{'Norad.Iss.On.Off'} eq "On") {
        warn "Conflict detected: ISS (25544) is in both the input file and .ini settings. " .
             "Please deactivate one to avoid duplication.";
    }
    if (grep { $_ == 20580 } @file_satellite_ids && $Globals::modules{'norad'}{'Norad.Hst.On.Off'} eq "On") {
        warn "Conflict detected: HST (20580) is in both the input file and .ini settings. " .
             "Please deactivate one to avoid duplication.";
    }

    # Combine settings and file IDs
    @satellite_ids = (@satellite_ids, @file_satellite_ids) unless @satellite_ids;

    # Step 2: Fetch TLE data for each satellite and save to TLE file
    fetch_and_save_tle_data(\@satellite_ids, $output_tle_file);

    # Step 3: Generate marker file with satellite-specific settings
    open my $marker_fh, '>', $marker_file or die "Could not open marker file '$marker_file': $!";

    foreach my $sat_id (@satellite_ids) {
        # Customize marker entry based on NORAD settings
        my ($image, $text, $detail) = ("default.png", "", "color=white altcirc=35");
        
        if ($sat_id == 25544 && $Globals::modules{'norad'}{'Norad.Iss.On.Off'} eq "On") {
            $image  = $Globals::modules{'norad'}{'Norad.Iss.Image'} // $image;
            $text   = $Globals::modules{'norad'}{'Norad.Iss.Text'} // "ISS";
            $detail = $Globals::modules{'norad'}{'Norad.Iss.Detail'} // $detail;
        } elsif ($sat_id == 20580 && $Globals::modules{'norad'}{'Norad.Hst.On.Off'} eq "On") {
            $image  = $Globals::modules{'norad'}{'Norad.Hst.Image'} // $image;
            $text   = $Globals::modules{'norad'}{'Norad.Hst.Text'} // "HST";
            $detail = $Globals::modules{'norad'}{'Norad.Hst.Detail'} // $detail;
        } elsif ($Globals::modules{'norad'}{'Norad.Sat.On.Off'} eq "On") {
            $image  = $Globals::modules{'norad'}{'Norad.Sat.Image'} // $image;
            $text   = $Globals::modules{'norad'}{'Norad.Sat.Text'} // "";
            $detail = $Globals::modules{'norad'}{'Norad.Sat.Detail'} // $detail;
        } else {
            next;
        }

        # Write customized entry to marker file
        print $marker_fh "$sat_id \"$text\" image=$image $detail\n";
    }
    close $marker_fh;

    # Message indicating successful update of the marker file
    print "NORAD Marker file successfully updated: $marker_file\n";
}

1; # End of the module
