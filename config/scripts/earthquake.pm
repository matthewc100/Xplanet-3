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

my $quakesettings = {
    'QuakePixelMax' => 10,
    'QuakePixelMin' => 2,
    'QuakePixelFactor' => 1.5,
    'QuakeDetailColor' => 'Multi',
    'QuakeDetailColorMin' => 'Blue',
    'QuakeDetailColorInt' => 'Yellow',
    'QuakeDetailColorMax' => 'Red',
    'QuakeCircleColor' => 'Multi',
    'QuakeMinimumSize' => 5,
    'QuakeImageList' => '',
    'QuakeImageTransparent' => 1,
    'QuakeDetailList' => '<date> <time> <lat> <long> <depth> <mag> <quality> <location>',
    'QuakeDetailAlign' => 'center',
    'QuakeReportingDuration' => 'day',
    'QuakeReportingSize' => 'significant',
};

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

sub colourisemag {
    my ($mag) = @_;
    my $quake_circle_colour = $quakesettings->{'QuakeCircleColor'};

    if ($quake_circle_colour =~ /Multi/i) {
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
        return $quake_circle_colour;
    }
}

# Subroutine to write out quake data to a marker file
sub WriteoutQuake {
    my ($drawcircles, @quakedata) = @_;

    # Trim any leading/trailing spaces from the file path
    $quake_marker_file =~ s/^\s+|\s+$//g;

    # Debugging output
    print "Debug: Writing to $quake_marker_file\n";

    open(my $qmf, ">", $quake_marker_file) or die "Cannot open $quake_marker_file: $!";

    foreach my $quake (@quakedata) {
        my @quakearray = split /,/, $quake;
        print "Debug: Processing quake entry: ", join(", ", @quakearray), "\n";

        my $mag = $quakearray[4];

        # Assuming colourisemag and drawcircle functions are working correctly
        my $circlecolour = colourisemag($mag);
        my $circlepixel = drawcircle($mag);
        my $textcolour = colourisetext($mag);

        print $qmf <<~"END";
            text={color=$textcolour, lat=$quakearray[2], long=$quakearray[3], text="$quakearray[0] $quakearray[1] $quakearray[4] $quakearray[5] $quakearray[6] $quakearray[7]"}
            END

        if ($drawcircles == 1) {
            print $qmf "circle={lat=$quakearray[2], long=$quakearray[3], radius=$circlepixel, color=$circlecolour, width=1}\n";
        }
    }

    close($qmf) or die "Cannot close $quake_marker_file: $!";
    print "Debug: Finished writing to $quake_marker_file\n";
}


# Subroutine to get quake feed based on reporting duration and size
sub get_Correct_quake_Feed {
    my $quake_reporting_duration = $quakesettings->{'QuakeReportingDuration'};
    my $quake_reporting_size = $quakesettings->{'QuakeReportingSize'};
    my $quakelocation = '';

    if ($quake_reporting_duration eq "day") {
        if ($quake_reporting_size eq "significant") {
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
    } elsif ($quake_reporting_duration eq "week") {
        if ($quake_reporting_size eq "significant") {
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
    } elsif ($quake_reporting_duration eq "month") {
        if ($quake_reporting_size eq "significant") {
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
}

# Subroutine to get quake data from the quake feed
sub get_quakedata {
    my $ua = LWP::UserAgent->new;
    $ua->timeout(60);
    $ua->env_proxy;

    my $quakelocation = $quake_location;
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
        # Debugging - use join to print each quake data on a new line
        #print "Quake Data:\n", join("\n", @quakedata), "\n";
        # After retrieving quake data, call WriteoutQuake and pass the data
        WriteoutQuake(1, @quakedata);  # Assuming you want to draw circles, pass @quakedata here


    } else {
        print "Failed to retrieve quake data: ", $res->status_line, "\n";
        return FAILED;
    }

    return 1;
}

1; # End of the module
