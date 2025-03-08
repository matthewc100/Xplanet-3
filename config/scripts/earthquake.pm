####################################
# ATTRIBUTION TO MICHAEL DEAR, who developed the logic for this code
# and shared it with the Xplanet community.  
# 
# Modified by Matthew Coblentz 
# 18 August 2024
# Original effort by Michael Dear gratefully acknowledged as this would not
# be possible otherwise.  
# 
# Major driver for this effort is the intent to move major funtionality into
# Perl modules rather than local subroutines, modernize external file
# fetching, and use of STRICT and WARNINGS which requires specific code cleanup in 
# main script.
####################################
package Earthquake;
use strict;
use warnings;
use Exporter 'import';
use LWP::UserAgent;
use HTTP::Request::Common;

# Import Globals
use Globals qw(
    %modules
    $quake_marker_file 
    @quakedata 
);

use Label qw(file_header);  # Import the file_header subroutine from the Label module

use constant FAILED => -1;

our @EXPORT_OK = qw(
    WriteoutQuake 
    get_quakedata
);
## EARTHQUAKE SITES
my $quake_location = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.csv";

my $quake_location_CSV_24H_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_day.csv";
my $quake_location_CSV_24H_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.csv";
my $quake_location_CSV_24H_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.csv";
my $quake_location_CSV_24H_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_day.csv";
my $quake_location_CSV_24H_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.csv";

my $quake_location_CSV_7D_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.csv";
my $quake_location_CSV_7D_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.csv";
my $quake_location_CSV_7D_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_week.csv";
my $quake_location_CSV_7D_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_week.csv";
my $quake_location_CSV_7D_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.csv";

my $quake_location_CSV_30D_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.csv";
my $quake_location_CSV_30D_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.csv";
my $quake_location_CSV_30D_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.csv";
my $quake_location_CSV_30D_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_month.csv";
my $quake_location_CSV_30D_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv";

# Subroutine to draw a circle based on magnitude
sub drawcircle {
    my ($mag) = @_;

    # Get quake symbol size model (case-insensitive)
    my $model = lc($Globals::modules{'quakes'}{'Quake.Symbol.Size.Model'} // 'max');  # Default to 'max'

    my $pixel;

    # Route processing based on the selected model
    if ($model eq 'max') {
        $pixel = max_model($mag);
    } elsif ($model eq 'max-min') {
        $pixel = max_min_model($mag);
    } elsif ($model eq 'standard') {
        $pixel = standard_model($mag);
    } else {
        print "Earthquake.pm Warning: Invalid Quake.Symbol.Size.Model '$model'. Defaulting to 'max'.\n";
        $pixel = max_model($mag);
    }

    return int($pixel + 0.5);  # Round to the nearest integer
}


sub max_model {
    my ($mag) = @_;
    my $pixel = $Globals::modules{'quakes'}{'Quake.Pixel.Max'} / 10;  # Get quakepixelmax from settings
    return $pixel * $mag;
}

sub max_min_model {
    my ($mag) = @_;
    my $max_pixel = $Globals::modules{'quakes'}{'Quake.Pixel.Max'};
    my $min_pixel = $Globals::modules{'quakes'}{'Quake.Pixel.Min'};
    $mag = 0 if $mag < 0;
    return $min_pixel + (($max_pixel - $min_pixel) * ($mag / 10));
}

sub standard_model {
    my ($mag) = @_;
    my $factor = $Globals::modules{'quakes'}{'Quake.Pixel.Factor'};
    return (($mag / 0.1) * 2 + 4) * $factor;
}

sub colourisetext {
    my ($mag) = @_;

    # Call colourisemag to determine the color
    my $colour = colourisemag($mag);

    my $quake_detail_colour = $Globals::modules{'quakes'}{'quake.pixel.color'} // ''; # Default to '' if undefined

    if ($quake_detail_colour ne 'multi') {

        if ($mag < 4) {
            $colour = $Globals::modules{'quakes'}{'quake.pixel.color.min'};
        } elsif ($mag > 5) {
            $colour = $Globals::modules{'quakes'}{'quake.pixel.color.int'};
        } else {
            $colour = $Globals::modules{'quakes'}{'quake.pixel.color.max'};
        }
    }
    return $colour;
}

sub colourisemag($) {
    my ($mag) = @_;
    
    # Normalize quakecirclecolor to lowercase for consistent handling
    my $quake_color = $Globals::modules{'quakes'}{'Quake.Circle.Color'} // '';  # Default to '' if undefined

    my $result;  # Store the return value temporarily

    # Check if quakecirclecolor is not 'multi'
    if (lc($quake_color) ne 'multi') {
        $result = $Globals::modules{'quakes'}{'Quake.Circle.Color'};  # Use the original value
    } else {
        # Traditional if-elsif-else structure for color selection based on magnitude
        if ($mag < 2.5) {
            $result = 'SeaGreen';
        } elsif ($mag < 3.0) {
            $result = 'PaleGreen';
        } elsif ($mag < 3.5) {
            $result = 'Green';
        } elsif ($mag < 4.0) {
            $result = 'ForestGreen';
        } elsif ($mag < 4.5) {
            $result = 'Khaki';  # Structural Damage
        } elsif ($mag < 5.0) {
            $result = 'LightGoldenrodYellow';
        } elsif ($mag < 5.5) {
            $result = 'Yellow';
        } elsif ($mag < 6.0) {
            $result = 'DarkGoldenrod';
        } elsif ($mag < 6.5) {
            $result = 'Salmon';  # Major Damage
        } elsif ($mag < 7.0) {
            $result = 'Orange';
        } elsif ($mag < 7.5) {
            $result = 'Tomato';
        } elsif ($mag < 8.0) {
            $result = 'OrangeRed';
        } elsif ($mag < 8.5) {
            $result = 'Red';  # End of Scale
        } elsif ($mag < 10.0) {
            $result = 'White';  # We are in the sh1t now :P
        } else {
            $result = 'Aquamarine';
        }
    }

    return $result;
}

# Subroutine to write out quake data to a marker file
sub WriteoutQuake {
    my ($drawcircles, @quakedata) = @_;

    open(my $qmf, ">", $quake_marker_file) or die "Cannot open $quake_marker_file: $!";
    Label::file_header('Earthquake', $qmf);  # Write header

    my $minimum_size = $Globals::modules{'quakes'}{'Quake.Minimum.Size'};  # Get the minimum magnitude

    foreach my $quake (@quakedata) {
        my @quakearray = split /,/, $quake;

        my $lat = sprintf("% 8.2f", $quakearray[1]);
        my $long = sprintf("% 9.2f", $quakearray[2]);
        my $mag = sprintf("%.1f", $quakearray[4]);

        if ($mag >= $minimum_size) {
            my $circlecolour = colourisemag($mag);
            my $circlepixel = drawcircle($mag);
            my $textcolour = colourisetext($mag);

            print $qmf "$lat $long \"\" color=$circlecolour symbolsize=$circlepixel\n";
            print $qmf "$lat $long \"$mag\" color=$textcolour align=Above\n";
        }
    }

    close($qmf) or die "Cannot close $quake_marker_file: $!";
}

# Subroutine to get quake feed based on reporting duration and size
sub get_Correct_quake_Feed {
    my $quake_reporting_duration = $Globals::modules{'quakes'}{'Quake.Reporting.Duration'};
    my $quake_reporting_size = $Globals::modules{'quakes'}{'Quake.Reporting.Size'};
    my $quakelocation = '';

    if (lc($quake_reporting_duration) eq "day") {
        if (lc($quake_reporting_size) eq "significant") {
            $quakelocation = $quake_location_CSV_24H_SIG;
        } elsif ($quake_reporting_size eq "4.5") {
            $quakelocation = $quake_location_CSV_24H_45;
        } elsif ($quake_reporting_size eq "2.5") {
            $quakelocation = $quake_location_CSV_24H_25;
        } elsif ($quake_reporting_size eq "1.0") {
            $quakelocation = $quake_location_CSV_24H_10;
        } else {
            $quakelocation = $quake_location_CSV_24H_ALL;
        }
    } elsif (lc($quake_reporting_duration) eq "week") {
        if (lc($quake_reporting_size) eq "significant") {
            $quakelocation = $quake_location_CSV_7D_SIG;
        } elsif ($quake_reporting_size eq "4.5") {
            $quakelocation = $quake_location_CSV_7D_45;
        } elsif ($quake_reporting_size eq "2.5") {
            $quakelocation = $quake_location_CSV_7D_25;
        } elsif ($quake_reporting_size eq "1.0") {
            $quakelocation = $quake_location_CSV_7D_10;
        } else {
            $quakelocation = $quake_location_CSV_7D_ALL;
        }
    } elsif (lc($quake_reporting_duration) eq "month") {
        if (lc($quake_reporting_size) eq "significant") {
            $quakelocation = $quake_location_CSV_30D_SIG;
        } elsif ($quake_reporting_size eq "4.5") {
            $quakelocation = $quake_location_CSV_30D_45;
        } elsif ($quake_reporting_size eq "2.5") {
            $quakelocation = $quake_location_CSV_30D_25;
        } elsif ($quake_reporting_size eq "1.0") {
            $quakelocation = $quake_location_CSV_30D_10;
        } else {
            $quakelocation = $quake_location_CSV_30D_ALL;
        }
    }
     return $quakelocation;  # Return the correct quake location
}

# Subroutine to get quake data from the quake feed
sub get_quakedata {
    my $update_interval = $Globals::modules{'labels'}{'Earthquake.update_interval'} // 86400; # Default 24h if not set
    my $last_update_time = -e $quake_marker_file ? (stat($quake_marker_file))[9] : 0;
    my $current_time = time();
    my $time_since_last_update = $current_time - $last_update_time;

    # **Check update frequency**
    if ($time_since_last_update < $update_interval) {
        my $next_update_in = $update_interval - $time_since_last_update;
        print "Earthquake update skipped: Next update allowed in $next_update_in seconds.\n";
        return;
    }

    print "Fetching earthquake data...\n";

    my $ua = LWP::UserAgent->new;
    $ua->timeout(60);
    $ua->env_proxy;

    # Get the correct quake feed URL
    my $quakelocation = Earthquake::get_Correct_quake_Feed();

    my $req = HTTP::Request->new(GET => $quakelocation);
    my $res = $ua->request($req);

    if ($res->is_success) {
        my $content = $res->decoded_content;
        my @lines = split /\n/, $content;

        my @quakedata;

        foreach my $line (@lines) {
            if ($line =~ /time,latitude,longitude/) {
                next;
            }
            push @quakedata, $line;
        }

        # **Write the new quake data**
        WriteoutQuake(1, @quakedata);  

        # **Update the timestamp on the marker file**
        utime(undef, undef, $quake_marker_file);
        print "Earthquake marker file updated: $quake_marker_file\n";
    } else {
        print "Earthquake::get_quakedata - Failed to retrieve quake data: ", $res->status_line, "\n";
        return FAILED;
    }

    return 1;
}



1; # End of the module
