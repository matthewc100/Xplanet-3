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
    my $pixel;
    my $pversion; # Declare $pversion here

    if ($quakesettings->{'QuakePixelMax'} =~ /\d/ && $quakesettings->{'QuakePixelMin'} !~ /\d/) {
        $pixel = max_model($mag);
    } elsif ($quakesettings->{'QuakePixelMax'} !~ /\d/ && $quakesettings->{'QuakePixelMin'} =~ /\d/) {
        $pixel = standard_model($mag);
        $pixel = $pixel + $quakesettings->{'QuakePixelMin'};
    } elsif ($quakesettings->{'QuakePixelMax'} =~ /\d/ && $quakesettings->{'QuakePixelMin'} =~ /\d/) {
        $pixel = max_min_model($mag);
    } else {
        $pixel = standard_model($mag);
    }

    if ($settings->{'XplanetVersion'} =~ /\w/) {
        if ($settings->{'XplanetVersion'} =~ /es/) {
            return $pixel;
        } else {
            my $xplanetversion = get_program_version();

            if ($xplanetversion =~ /(\d.\d\d)(\w)/) {
                my ($pversion, $prevision) = ($1, $2);
                $pversion *= 1;
            }

            if ($pversion < 0.99) {
                $pixel = $pixel * 2;
            }

            return $pixel;
        }
    }
}

sub max_model {
    my ($mag) = @_;
    my $pixel = $quakesettings->{'QuakePixelMax'} / 10;
    $pixel = $pixel * $mag;
    return $pixel;
}

sub max_min_model {
    my ($mag) = @_;
    my $max_pixel = $quakesettings->{'QuakePixelMax'};
    my $min_pixel = $quakesettings->{'QuakePixelMin'};
    my $pixel_diff = $max_pixel - $min_pixel;
    my $pixel = $pixel_diff / 10;
    $pixel = $pixel * $mag;
    $pixel = $pixel_diff + $min_pixel;
    return $pixel;
}

sub standard_model {
    my ($mag) = @_;
    my $factor = $quakesettings->{'QuakePixelFactor'};
    my $pixel = $mag / 0.1;
    $pixel = $pixel * 2;
    $pixel = $pixel + 4;
    $pixel = $pixel * $factor;
    return $pixel;
}

sub colourisetext {
    my ($mag) = @_;
    my $quake_detail_colour = $quakesettings->{'QuakeDetailColor'};

    if ($quake_detail_colour =~ /Multi/i) {
        my $quake_detail_min = $quakesettings->{'QuakeDetailColorMin'};
        my $quake_detail_int = $quakesettings->{'QuakeDetailColorInt'};
        my $quake_detail_max = $quakesettings->{'QuakeDetailColorMax'};
        my $colour;

        if ($mag < 4) {
            $colour = $quake_detail_min;
        } elsif ($mag > 5) {
            $colour = $quake_detail_max;
        } else {
            $colour = $quake_detail_int;
        }

        return $colour;
    } else {
        return $quake_detail_colour;
    }
}

sub colourisemag($) {
    my ($mag)=@_;
    
    if ($quakesettings->{'QuakeCircleColor'} !~ /Multi/) {
        return $quakesettings->{'QuakeCircleColor'};
    }
    else {
        return 'SeaGreen'               if $mag < 2.5;
        return 'PaleGreen'              if $mag < 3.0;
        return 'Green'                  if $mag < 3.5;
        return 'ForestGreen'            if $mag < 4.0;
        return 'Khaki'                  if $mag < 4.5; # Structal Damage
        return 'LightGoldenrodYellow'   if $mag < 5.0;
        return 'Yellow'                 if $mag < 5.5;
        return 'DarkGoldenrod'          if $mag < 6.0;
        return 'Salmon'                 if $mag < 6.5; # Major Damage
        return 'Orange'                 if $mag < 7.0;
        return 'Tomato'                 if $mag < 7.5;
        return 'OrangeRed'              if $mag < 8.0;
        return 'Red'                    if $mag < 8.5; # End of Scale
        return 'White'                  if $mag < 10; # We are in the sh1t now :P
        return 'Aquamarine';
    }
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
    
    my $minimum_size = $quakesettings->{'QuakeMinimumSize'};  # Get the minimum magnitude from settings

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
            my $circlepixel = drawcircle($mag);
            my $textcolour = colourisetext($mag);

            # First line with empty text
            print $qmf "$lat $long \"\" color=$circlecolour symbolsize=$circlepixel\n";

            # Second line with magnitude text, color, and alignment
            print $qmf "$lat $long \"$mag\" color=$textcolour align=Above\n";
        }
    }

    close($qmf) or die "Cannot close $quake_marker_file: $!";
    print "Updated quake marker file\n";
}



# Subroutine to get quake feed based on reporting duration and size
sub get_Correct_quake_Feed {
    my $quake_reporting_duration = $quakesettings->{'QuakeReportingDuration'};
    my $quake_reporting_size = $quakesettings->{'QuakeReportingSize'};
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
