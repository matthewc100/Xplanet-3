package Earthquake;
use strict;
use warnings;
use Exporter 'import';
use LWP::UserAgent;
use HTTP::Request::Common;

use Globals qw(
    $quakesettings 
    $settings 
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

    # Normalize the model name for consistent comparison
    my $model = lc($quakesettings->{'quakesymbolsizemodel'} // 'max');  # Default to 'max'

    # Debugging: Output the selected model
    print "Earthquake.pm Debug: Selected QuakeSymbolSizeModel = $model\n";

    my $pixel;

    # Route processing based on the selected model
    if ($model eq 'max') {
        $pixel = max_model($mag);
    } elsif ($model eq 'max-min') {
        $pixel = max_min_model($mag);
    } elsif ($model eq 'standard') {
        $pixel = standard_model($mag);
    } else {
        # Fallback to 'max' if an invalid model is provided
        print "Earthquake.pm Warning: Invalid QuakeSymbolSizeModel '$model'. Defaulting to 'max'.\n";
        $pixel = max_model($mag);
    }

    # Round to the nearest integer
    my $rounded_pixel = int($pixel + 0.5);

    # Debugging: Output the rounded pixel size
    print "Earthquake.pm Debug: Calculated symbolsize = $pixel, Rounded = $rounded_pixel for magnitude = $mag using model = $model\n";

    return $rounded_pixel;
}


sub max_model {
    my ($mag) = @_;
    my $pixel = $quakesettings->{'quakepixelmax'} / 10;
    print "Earthquake.pm:90 Debug: quakepixelmax = $quakesettings->{'quakepixelmax'}\n";

    $pixel = $pixel * $mag;
    print "Earthquake.pm:93 Debug: max_model - pixel = $pixel, magnitude = $mag\n";

    return $pixel;
}

sub max_min_model {
    my ($mag) = @_;
    my $max_pixel = $quakesettings->{'quakepixelmax'};  # Max size from .ini
    my $min_pixel = $quakesettings->{'quakepixelmin'};  # Min size from .ini

    # Ensure $mag is within a reasonable range (optional safety check)
    $mag = 0 if $mag < 0;

    # Scale pixel size based on magnitude
    my $scaled_pixel = $min_pixel + (($max_pixel - $min_pixel) * ($mag / 10));

    # Debugging
    print "Debug: max_pixel = $max_pixel, min_pixel = $min_pixel, magnitude = $mag, scaled_pixel = $scaled_pixel\n";

    return $scaled_pixel;
}


sub standard_model {
    my ($mag) = @_;
    my $factor = $quakesettings->{'quakepixelfactor'};
    my $pixel = $mag / 0.1;
    $pixel = $pixel * 2;
    $pixel = $pixel + 4;
    $pixel = $pixel * $factor;
    print "Earthquake.pm:118 Debug: max_model - pixel = $pixel, magnitude = $mag\n";

    return $pixel;
}

sub colourisetext {
    my ($mag) = @_;

    # Call colourisemag to determine the color
    my $colour = colourisemag($mag);

    my $quake_detail_colour = lc($quakesettings->{'quakepixelcolor'} // ''); # Default to '' if undefined

    if ($quake_detail_colour ne 'multi') {

        if ($mag < 4) {
            $colour = $quakesettings->{'quakepixelcolormin'};
        } elsif ($mag > 5) {
            $colour = $quakesettings->{'quakepixelcolorint'};
        } else {
            $colour = $quakesettings->{'quakepixelcolormax'};
        }
    }
    return $colour;
}

sub colourisemag($) {
    my ($mag) = @_;
    print "Earthquake.pm Debug:146 magnitude = $mag\n";

    # Normalize quakecirclecolor to lowercase for consistent handling
    my $quake_color = lc($quakesettings->{'quakecirclecolor'} // '');  # Default to '' if undefined
    print "Earthquake.pm Debug:150 quakecirclecolor (normalized) = $quake_color\n";

    my $result;  # Store the return value temporarily

    # Check if quakecirclecolor is not 'multi'
    if ($quake_color ne 'multi') {
        $result = $quakesettings->{'quakecirclecolor'};  # Use the original value
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

    # Debug output for the return value
    print "Earthquake.pm Debug:193 Returning value = $result\n";

    return $result;
}

# Subroutine to write out quake data to a marker file
sub WriteoutQuake {
    my ($drawcircles, @quakedata) = @_;

    # Ensure the file path is properly trimmed
    $quake_marker_file =~ s/^\s+|\s+$//g;

    # Debugging output
    #print "Debug: Writing to $quake_marker_file\n";

    open(my $qmf, ">", $quake_marker_file) or die "Cannot open $quake_marker_file: $!";

    # Call file_header to write the header to the marker file
    Label::file_header('Earthquake', $qmf);  # Passing the filehandle to the file_header subroutine
    
    my $minimum_size = $quakesettings->{'quakeminimumsize'};  # Get the minimum magnitude from settings

    foreach my $quake (@quakedata) {
        my @quakearray = split /,/, $quake;
        #print "Debug: Processing quake entry: ", join(", ", @quakearray), "\n";

        my $lat =  sprintf("% 8.2f", $quakearray[1]);  # Latitude with 2 decimal places, right-aligned, total width 8
        my $long = sprintf("% 9.2f", $quakearray[2]);  # Longitude with 2 decimal places, right-aligned, total width 9
        my $mag =  sprintf("%.1f", $quakearray[4]);   # Magnitude with 1 decimal place

        # Check if the magnitude meets the minimum size requirement
        if ($mag >= $minimum_size) {

            # Assuming colourisemag and drawcircle functions are working correctly
            my $circlecolour = colourisemag($mag);
            print "Earthquake.pm debug:228 Magnitude passed to drawcircle = $mag\n";
            my $circlepixel = drawcircle($mag);
            my $textcolour = colourisetext($mag);

            # First line with empty text
            print $qmf "$lat $long \"\" color=$circlecolour symbolsize=$circlepixel\n";

            # Second line with magnitude text, color, and alignment
            print $qmf "$lat $long \"$mag\" color=$textcolour align=Above\n";
        }
    }

    close($qmf) or die "Cannot close $quake_marker_file: $!";
    print "Updated quake marker file: $quake_marker_file\n";
}

# Subroutine to get quake feed based on reporting duration and size
sub get_Correct_quake_Feed {
    my $quake_reporting_duration = $quakesettings->{'quakereportingduration'};
    my $quake_reporting_size = $quakesettings->{'quakereportingsize'};
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
        # After retrieving quake data, call WriteoutQuake and pass the data
        WriteoutQuake(1, @quakedata);  # Assuming you want to draw circles
    } else {
        print "Failed to retrieve quake data: ", $res->status_line, "\n";
        return FAILED;
    }

    return 1;
}


1; # End of the module
