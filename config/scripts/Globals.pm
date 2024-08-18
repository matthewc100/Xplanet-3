package Globals;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    $quakesettings 
    $settings 
    $quake_marker_file
    @quakedata
    $quake_location 
    $quake_location_CSV_24H_SIG 
    $quake_location_CSV_24H_45 
    $quake_location_CSV_24H_25 
    $quake_location_CSV_24H_10 
    $quake_location_CSV_24H_ALL 
    $quake_location_CSV_7D_SIG 
    $quake_location_CSV_7D_45 
    $quake_location_CSV_7D_25 
    $quake_location_CSV_7D_10 
    $quake_location_CSV_7D_ALL
    $quake_location_CSV_30D_SIG 
    $quake_location_CSV_30D_45 
    $quake_location_CSV_30D_25 
    $quake_location_CSV_30D_10 
    $quake_location_CSV_30D_ALL
    $Earthquake
    set_quake_marker_file
    set_quakedata
    set_quake_location
    set_pversion

    $noradsettings 
    $isstle_file 
    $iss_file 
    $xplanet_satellites_dir 
    $iss_location 
    $hst_location 
    $sts_location 
    $other_locations1 
    $xplanet_images_dir 
    get_webpage

    $volcano_marker_file
    $volcano_location
    $volcanosettings

    $storm_past_location
    $storm_future_location
    $storm_base_location
    $hurricane_arc_file
    $hurricane_marker_file

    $label_file

    $cloudsettings

    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_location
    $eclipse_marker_file
    @eclipsedata
    @eclipsetrack
    @eclipserefined
);

our $quakesettings = {
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

our (
    $noradsettings, 
    $isstle_file, 
    $iss_file, 
    $xplanet_satellites_dir, 
    $iss_location, 
    $hst_location, 
    $sts_location, 
    $other_locations1,
    $xplanet_images_dir,
    $volcano_marker_file,
    $volcano_location,
    $volcanosettings,
    $storm_past_location,
    $storm_future_location,
    $storm_base_location,
    $hurricane_arc_file,
    $hurricane_marker_file,
    $label_file,
    $eclipse_arc_file,
    $eclipse_data_file,
    $eclipse_location,
    $eclipse_marker_file,
    @eclipsedata,
    @eclipsetrack,
    @eclipserefined
);

$volcanosettings = {
    'VolcanoCircleColorInner' => 'Red',
    'VolcanoCircleSizeInner' => 3,
    'VolcanoCircleColorMiddle' => 'Yellow',
    'VolcanoCircleSizeMiddle' => 5,
    'VolcanoNameOnOff' => 'On',
    'VolcanoImageList' => '',
    'VolcanoImageTransparent' => '',
    'VolcanoCircleColorOuter' => 'Blue',
    'VolcanoCircleSizeOuter' => 7,
    'VolcanoNameAlign' => 'Left',
    'VolcanoNameColor' => 'Black',
    'VolcanoDetailList' => '<name> - <location>',
    'VolcanoDetailColor' => 'White',
    'VolcanoDetailAlign' => 'Right'
};

our $cloudsettings = {
    'CloudMirrorA' => 'http://example.com/mirrorA',
    'CloudMirrorB' => 'http://example.com/mirrorB',
    'CloudMirrorC' => 'http://example.com/mirrorC',
    'CloudMirrorD' => 'http://example.com/mirrorD',
    'CloudMirrorE' => 'http://example.com/mirrorE',
    'CloudMirrorF' => 'http://example.com/mirrorF',
    'CloudMirrorG' => 'http://example.com/mirrorG',
    'CloudMirrorH' => 'http://example.com/mirrorH',
    'CloudMirrorI' => 'http://example.com/mirrorI',
    'CloudMirrorJ' => 'http://example.com/mirrorJ',
    'CloudMirrorK' => 'http://example.com/mirrorK',
    'CloudMirrorL' => 'http://example.com/mirrorL',
    'CloudMirrorM' => 'http://example.com/mirrorM',
    'CloudMirrorN' => 'http://example.com/mirrorN'
};

our $quake_location_CSV_24H_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_day.csv";
our $quake_location_CSV_24H_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.csv";
our $quake_location_CSV_24H_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.csv";
our $quake_location_CSV_24H_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_day.csv";
our $quake_location_CSV_24H_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.csv";

our $quake_location_CSV_7D_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.csv";
our $quake_location_CSV_7D_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.csv";
our $quake_location_CSV_7D_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_week.csv";
our $quake_location_CSV_7D_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_week.csv";
our $quake_location_CSV_7D_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_week.csv";

our $quake_location_CSV_30D_SIG = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.csv";
our $quake_location_CSV_30D_45 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_month.csv";
our $quake_location_CSV_30D_25 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_month.csv";
our $quake_location_CSV_30D_10 = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_month.csv";
our $quake_location_CSV_30D_ALL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv";

our $settings = {
    'XplanetVersion' => '1.2.3es',
    'pversion' => undef,
};

our $quake_marker_file;
our @quakedata;
our $quake_location;
our $Earthquake;

# Setter function to set the value of $quake_marker_file
sub set_quake_marker_file {
    my ($value) = @_;
    $quake_marker_file = $value;
}

# Setter function to set the value of @quakedata
sub set_quakedata {
    my (@data) = @_;
    @quakedata = @data;
}

# Setter function to set the value of $quake_location
sub set_quake_location {
    my ($value) = @_;
    $quake_location = $value;
}

# Setter function to set the value of $pversion in $settings
sub set_pversion {
    my ($value) = @_;
    $settings->{'pversion'} = $value;
}

sub get_webpage {
    my ($url) = @_;
    # Add the logic to fetch the webpage here
    # This is a placeholder
    return "webpage content";
}

1; # End of the module
