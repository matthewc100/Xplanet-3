package Globals;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    $settings
    $xplanet_dir
    $settings_ini_file
    update_directories
    $xplanet_markers_dir
    $xplanet_arcs_dir
    $xplanet_images_dir
    $xplanet_config_dir
    $xplanet_satellites_dir

    $quakesettings 
    @quakedata
    $Earthquake
    $quake_marker_file

    set_pversion

    $noradsettings
    $iss_file
    $isstle_file
 
    get_webpage

    $volcano_marker_file
    $volcanosettings 

    $stormsettings
    $hurricane_arc_file
    $hurricane_marker_file

    $labelsettings
    $label_file

    $cloudsettings 

    $eclipse_marker_file
    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_location
    $eclipse_marker_file
    @eclipsedata
    @eclipsetrack
    @eclipserefined
);

our (
    $settings,
    $xplanet_markers_dir,
    $xplanet_arcs_dir,
    $xplanet_satellites_dir,
    $xplanet_images_dir,
    $xplanet_config_dir,
    $settings_ini_file,
    
    $noradsettings,
    $iss_file,
    $isstle_file,

    $cloudsettings,

    $quake_marker_file,
    @quakedata,
    $quake_location,
    $quakesettings, 
    $Earthquake,

    $volcano_marker_file,
    $volcanosettings,

    $stormsettings,
    $hurricane_arc_file,
    $hurricane_marker_file,

    $label_file,
    $labelsettings,

    $eclipse_arc_file,
    $eclipse_data_file,
    $eclipse_location,
    $eclipse_marker_file,
    @eclipsedata,
    @eclipsetrack,
    @eclipserefined
);

# $volcanosettings = {
#     'VolcanoCircleColorInner' => 'Red',
#     'VolcanoCircleSizeInner' => 3,
#     'VolcanoCircleColorMiddle' => 'Yellow',
#     'VolcanoCircleSizeMiddle' => 5,
#     'VolcanoNameOnOff' => 'On',
#     'VolcanoImageList' => '',
#     'VolcanoImageTransparent' => '',
#     'VolcanoCircleColorOuter' => 'Blue',
#     'VolcanoCircleSizeOuter' => 7,
#     'VolcanoNameAlign' => 'Left',
#     'VolcanoNameColor' => 'Black',
#     'VolcanoDetailList' => '<name> - <location>',
#     'VolcanoDetailColor' => 'White',
#     'VolcanoDetailAlign' => 'Right'
# };

#################################################
#  CONFIGURATION SECTION                        #
#################################################
#
# 10 September 2024
# 
# Many of the variables and settings needed to be rescoped appropriately.  By moving the configuration
# variables to the Globals.pm module, we can better support maintenance and future updates.  
#
# Please note if you are using Windows and Active Perl you must \\ your directories not just use \
# where xplanet is installed
#
# We refactored the directory and file path declarations to be maintained in this Globals.pm
# module.  Also, it seemed easier to make this a subroutine for maintenance.  Since $xplanet_dir is 
# the root directory for many configurations, it’s a great idea to define it in the .ini file and 
# read it into Globals.pm. This will allow flexibility if the directory changes in the future. 
#
# Initialize variables that remain CONSTANT
#

our $xplanet_dir;  # Declare it globally in Globals
# Setter function to set the value of $xplanet_dir
sub set_xplanet_dir {
    my ($value) = @_;
    $xplanet_dir = $value;
}

sub get_ini_settings {
    my $settings_ini_file = "$ENV{'XPLANET_DIR'}\\config\\totalmarker.ini";
    open (MF, "<$settings_ini_file") or die "Could not open settings file: $!";
    
    while (<MF>) {
        chomp;  # Remove newline characters
        next if /^\s*$/ || /^\s*#/;  # Skip empty lines or comments
        
        my ($setting, $value) = split("=", $_, 2);
        
        # Strip quotes if they exist around the value
        $value =~ s/^"(.*)"$/$1/;  # Removes double quotes from around the value if present

        if ($setting eq 'xplanet_dir') {
            $xplanet_dir = $value;
            update_directories();  # Update directory paths based on the root
        }
        
        # Other settings processing
    }
    close MF;
}

sub update_directories {
    # Function to update directory paths based on xplanet_dir
    # Directory Layout
    #

    $xplanet_markers_dir = $ENV{'XPLANET_MARKERS_DIR'} || "$xplanet_dir\\markers";
    $xplanet_arcs_dir = $ENV{'XPLANET_ARC_DIR'} || "$xplanet_dir\\arcs";
    $xplanet_satellites_dir = $ENV{'XPLANET_SATELLITES_DIR'} || "$xplanet_dir\\satellites";
    $xplanet_images_dir = $ENV{'XPLANET_IMAGE_DIR'} || "$xplanet_dir\\images";
    $xplanet_config_dir = $ENV{'XPLANET_CONFIG_DIR'} || "$xplanet_dir\\config";

    $quake_marker_file = "$xplanet_markers_dir\\quake";
    $volcano_marker_file = "$xplanet_markers_dir\\volcano";
    $hurricane_marker_file = "$xplanet_markers_dir\\storm";
    $hurricane_arc_file = "$xplanet_arcs_dir\\storm";
    $label_file = "$xplanet_markers_dir\\updatelabel";
    $eclipse_marker_file = "$xplanet_markers_dir\\eclipse";
    $eclipse_arc_file = "$xplanet_arcs_dir\\eclipse";
    $eclipse_data_file = "$xplanet_config_dir\\totalmarker.dat";
    $settings_ini_file = "$xplanet_config_dir\\totalmarker.ini";
    $iss_file = "$xplanet_satellites_dir\\tm";
    $isstle_file = "$xplanet_satellites_dir\\tm.tle";
}

## DYNAMIC VARIABLES
# Declare the global variables that will be set dynamically

#################################################
#  END CONFIGURATION SECTION                    #
#################################################
$settings = {
    'XplanetVersion' => '1.2.3es',
    'pversion' => undef,
};


# Setter function to set the value of $pversion in $settings
sub set_pversion {
    my ($value) = @_;
    $settings->{'pversion'} = $value;
}

use LWP::UserAgent;

sub get_webpage {
    # Explanation:
        # Using LWP::UserAgent:#  ::UserAgent is a Perl module used for web requests. It allows for more control over the HTTP requests 
        # compared to LWP::Simple, such as setting custom timeouts, handling headers, and error responses.
    # Setting the User Agent:
        # The user agent string is set to mimic a common web browser or a custom identifier (xPlanetBot/1.0). This helps ensure that the 
        # request is accepted by most web servers.
    # Handling Timeouts:
        # A timeout of 15 seconds is set to prevent the script from hanging indefinitely if a server is unresponsive.
    # Fetching the Webpage:
        # The get() method is used to send an HTTP GET request to the provided URL. If the request is successful, the subroutine returns 
        # the decoded content of the webpage.
        # If the request fails (e.g., due to a server error or network issue), the error is printed to the console, and the subroutine returns 'FAILED'.
    # Return Values:
        # On success, the subroutine returns the content of the fetched webpage.
        # On failure, it returns 'FAILED'.
        
    my ($url) = @_;  # The URL from which the webpage content will be fetched.
    
    # Create a new LWP::UserAgent object.
    my $ua = LWP::UserAgent->new;
    
    # Set the user agent's timeout (in seconds) to prevent it from hanging indefinitely.
    $ua->timeout(15);
    
    # Set the user agent's HTTP request header to identify the source.
    $ua->agent('Mozilla/5.0 (compatible; xPlanetBot/1.0)');

    # Send the HTTP GET request to the specified URL.
    my $response = $ua->get($url);

    # Check if the request was successful.
    if ($response->is_success) {
        # Return the content of the webpage if the request was successful.
        return $response->decoded_content;
    } else {
        # Return a failure message if the request failed.
        print "Failed to fetch $url: " . $response->status_line . "\n";
        return 'FAILED';
    }
}

#   sub file_header($) {
#       my ($openfile) = @_;
#       print MF "# This $openfile marker file created by $Script - $Client version $VERSION\n";
#       print MF "# For more information read the top of the $Script file or go to\n";
#       print MF "# https://github.com/matthewc100/Xplanet-3\n";
#       $tsn = localtime(time);
#       print MF "# Last Updated: $tsn\n#\n";
#   }

sub get_settings {
    # Get_Settings subroutine
    #   This section of code is part of a subroutine that processes configuration settings, likely read from a file (e.g., an .ini file), 
    #   and stores them in a hash called $labelsettings. Here’s a detailed explanation of what this code is doing and how it works: 
    #
    # What the Code Is Doing
    #   Processing Each Line: The code is likely iterating over lines from a configuration file (e.g., an .ini file). Each line is split into a 
    #   setting name ($setting) and a value ($result).
    # 
    #   Matching and Storing Settings: The if ($data1 =~ /Label/) condition checks if the current line is related to the "Label" section in the 
    #   configuration. If it is, the code matches the specific setting name ($setting) using elsif statements and stores the corresponding value 
    #   ($result) in the $labelsettings hash.
    # 
    # Key Concepts
    #   $labelsettings Hash: 
    #       $labelsettings is a hash that stores configuration settings related to "Label." Each key in the hash corresponds to a 
    #       specific setting (e.g., 'LabelWarningQuake', 'LabelWarningVolcano'), and the value associated with each key is the setting's value as read 
    #       from the configuration file.
    # 
    #   $setting and $result: 
    #       $setting represents the name of the setting being processed (e.g., 'LabelWarningQuake'), and $result is the value of that setting. 
    #       These are stored in the $labelsettings hash.
    #
    # 9 September 2024
    # Key Improvements:
    # 1. Removed Unnecessary $data1 and $tmp1: The variables $data1 and $tmp1 were not needed, so they have been removed for simplicity.
    # 2. Direct Processing Based on $setting: The script now processes each line based directly on the $setting name. This simplifies 
    #    the logic and makes it easier to maintain.
    # 3. Efficient Debugging: The print statement now only prints $setting and $result, making the debugging output clearer.
    # 4. Proper Error Handling for File Opening: Added an error message to handle the case where the settings file cannot be opened.
    #
    # How It Works:
    #    Skipping Comments and Empty Lines: The next statements ensure that comments and empty lines are ignored.
    #    Splitting =: The line is split into $setting and $result based on the = sign.
    #    Pattern Matching on $setting: Depending on whether the setting relates to Quake, Volcano, Storm, etc., the appropriate hash is updated.
    #
    # Summary
    #    Simplified Code: By removing the unnecessary $data1 and $tmp1 variables, the code is cleaner and easier to read.
    #    Direct Matching of Settings: The settings are now matched directly based on the $setting value.
    #    Improved Debugging: The debug output is simplified and only prints relevant information.
    #    These settings are now properly scoped to be global. 
    open (MF, "<$settings_ini_file") or die "Could not open settings file: $!";

    while (<MF>) {
        chomp;  # Remove newline characters

        # Skip empty lines and comments (assuming comments start with '#')
        next if /^\s*$/;  # Skip empty lines
        next if /^\s*#/;  # Skip lines starting with '#'
        
        # Split the line into $setting and $result, with default values
        my ($setting, $result) = split("=", $_, 2);
        $setting //= '';  # Default to empty string if not defined
        $result //= '';   # Default to empty string if not defined
            
        if ($setting =~ /^Quake/) {
            if ($setting =~ /QuakeDetailColorMin/) {$quakesettings->{'QuakeDetailColorMin'} = $result;}
            elsif ($setting =~ /QuakeDetailColorInt/) {$quakesettings->{'QuakeDetailColorInt'} = $result;}
            elsif ($setting =~ /QuakeDetailColorMax/) {$quakesettings->{'QuakeDetailColorMax'} = $result;}
            elsif ($setting =~ /QuakeDetailAlign/) {$quakesettings->{'QuakeDetailAlign'} = $result;}
            elsif ($setting =~ /QuakeCircleColor/) {$quakesettings->{'QuakeCircleColor'} = $result;}
            elsif ($setting =~ /QuakePixelMax/) {$quakesettings->{'QuakePixelMax'} = $result;}
            elsif ($setting =~ /QuakePixelMin/) {$quakesettings->{'QuakePixelMin'} = $result;}
            elsif ($setting =~ /QuakePixelFactor/) {$quakesettings->{'QuakePixelFactor'} = $result;}
            elsif ($setting =~ /QuakeImageTransparent/) {$quakesettings->{'QuakeImageTransparent'} = $result;}
            elsif ($setting =~ /QuakeImageList/) {$quakesettings->{'QuakeImageList'} = $result;}
            elsif ($setting =~ /QuakeDetailColor/) {$quakesettings->{'QuakeDetailColor'} = $result;}
            elsif ($setting =~ /QuakeDetailList/) {$quakesettings->{'QuakeDetailList'} = $result;}
            elsif ($setting =~ /QuakeMinimumSize/) {$quakesettings->{'QuakeMinimumSize'} = $result;}
            elsif ($setting =~ /QuakeReportingDuration/) {$quakesettings->{'QuakeReportingDuration'} = $result;}
            elsif ($setting =~ /QuakeReportingSize/) {$quakesettings->{'QuakeReportingSize'} = $result;}
            elsif ($setting =~ /QuakeFade/) {$quakesettings->{'QuakeFade'} = $result;}                      
        }
            
        elsif ($setting =~ /^Volcano/) {
            if ($setting =~ /VolcanoCircleSizeInner/) {$volcanosettings->{'VolcanoCircleSizeInner'} = $result;}
            elsif ($setting =~ /VolcanoCircleSizeMiddle/) {$volcanosettings->{'VolcanoCircleSizeMiddle'} = $result;}
            elsif ($setting =~ /VolcanoCircleSizeOuter/) {$volcanosettings->{'VolcanoCircleSizeOuter'} = $result;}
            elsif ($setting =~ /VolcanoCircleColorInner/) {$volcanosettings->{'VolcanoCircleColorInner'} = $result;}
            elsif ($setting =~ /VolcanoCircleColorMiddle/) {$volcanosettings->{'VolcanoCircleColorMiddle'} = $result;}
            elsif ($setting =~ /VolcanoCircleColorOuter/) {$volcanosettings->{'VolcanoCircleColorOuter'} = $result;}
            elsif ($setting =~ /VolcanoNameOnOff/) {$volcanosettings->{'VolcanoNameOnOff'} = $result;}
            elsif ($setting =~ /VolcanoNameColor/) {$volcanosettings->{'VolcanoNameColor'} = $result;}
            elsif ($setting =~ /VolcanoNameAlign/) {$volcanosettings->{'VolcanoNameAlign'} = $result;}
            elsif ($setting =~ /VolcanoImageTransparent/) {$volcanosettings->{'VolcanoImageTransparent'} = $result;}
            elsif ($setting =~ /VolcanoImageList/) {$volcanosettings->{'VolcanoImageList'} = $result;}
            elsif ($setting =~ /VolcanoDetailAlign/) {$volcanosettings->{'VolcanoDetailAlign'} = $result;}
            elsif ($setting =~ /VolcanoDetailList/) {$volcanosettings->{'VolcanoDetailList'} = $result;}
            elsif ($setting =~ /VolcanoDetailColor/) {$volcanosettings->{'VolcanoDetailColor'} = $result;}
        }
            
        elsif ($setting =~ /^Storm/) {
            if ($setting =~ /StormColorTrackReal/) {$stormsettings->{'StormColorTrackReal'} = $result;}
            elsif ($setting =~ /StormColorTrackPrediction/) {$stormsettings->{'StormColorTrackPrediction'} = $result;}
            elsif ($setting =~ /StormColorName/) {$stormsettings->{'StormColorName'} = $result;}
            elsif ($setting =~ /StormColorDetail/) {$stormsettings->{'StormColorDetail'} = $result;}
            elsif ($setting =~ /StormAlignName/) {$stormsettings->{'StormAlignName'} = $result;}
            elsif ($setting =~ /StormAlignDetail/) {$stormsettings->{'StormAlignDetail'} = $result;}
            elsif ($setting =~ /StormImageTransparent/) {$stormsettings->{'StormImageTransparent'} = $result;}
            elsif ($setting =~ /StormImageList/) {$stormsettings->{'StormImageList'} = $result;}
            elsif ($setting =~ /StormDetailAlign/) {$stormsettings->{'StormDetailAlign'} = $result;}
            elsif ($setting =~ /StormDetailList/) {$stormsettings->{'StormDetailList'} = $result;}
            elsif ($setting =~ /StormTrackOnOff/) {$stormsettings->{'StormTrackOnOff'} = $result;}
            elsif ($setting =~ /StormNameOnOff/) {$stormsettings->{'StormNameOnOff'} = $result;}
        }
            
        elsif ($setting =~ /^Eclipse/) {
            if ($setting =~ /EclipseOnOff/) {$settings->{'EclipseOnOff'} = $result;}
            elsif ($setting =~ /EclipseNotifyOnOff/) {$settings->{'EclipseNotifyOnOff'} = $result;}
            elsif ($setting =~ /EclipseNotifyTimeHours/) {$settings->{'EclipseNotifyTimeHours'} = $result;}
        }
            
        elsif ($setting =~ /^Norad/) {
            if ($setting =~ /NoradIssImage/) {$noradsettings->{'NoradIssImage'} = $result;}
            elsif ($setting =~ /NoradIssText/) {$noradsettings->{'NoradIssText'} = $result;}
            elsif ($setting =~ /NoradIssDetail/) {$noradsettings->{'NoradIssDetail'} = $result;}
            elsif ($setting =~ /NoradIssOnOff/) {$noradsettings->{'NoradIssOnOff'} = $result;}
            elsif ($setting =~ /NoradHstImage/) {$noradsettings->{'NoradHstImage'} = $result;}
            elsif ($setting =~ /NoradHstText/) {$noradsettings->{'NoradHstText'} = $result;}
            elsif ($setting =~ /NoradHstDetail/) {$noradsettings->{'NoradHstDetail'} = $result;}
            elsif ($setting =~ /NoradHstOnOff/) {$noradsettings->{'NoradHstOnOff'} = $result;}
            elsif ($setting =~ /NoradSoyuzImage/) {$noradsettings->{'NoradSoyuzImage'} = $result;}
            elsif ($setting =~ /NoradSoyuzText/) {$noradsettings->{'NoradSoyuzText'} = $result;}
            elsif ($setting =~ /NoradSoyuzDetail/) {$noradsettings->{'NoradSoyuzDetail'} = $result;}
            elsif ($setting =~ /NoradSoyuzOnOff/) {$noradsettings->{'NoradSoyuzOnOff'} = $result;}
            elsif ($setting =~ /NoradStsImage/) {$noradsettings->{'NoradStsImage'} = $result;}
            elsif ($setting =~ /NoradStsText/) {$noradsettings->{'NoradStsText'} = $result;}
            elsif ($setting =~ /NoradStsDetail/) {$noradsettings->{'NoradStsDetail'} = $result;}
            elsif ($setting =~ /NoradStsOnOff/) {$noradsettings->{'NoradStsOnOff'} = $result;}
            elsif ($setting =~ /NoradSatImage/) {$noradsettings->{'NoradSatImage'} = $result;}
            elsif ($setting =~ /NoradSatText/) {$noradsettings->{'NoradSatText'} = $result;}
            elsif ($setting =~ /NoradSatDetail/) {$noradsettings->{'NoradSatDetail'} = $result;}
            elsif ($setting =~ /NoradSatOnOff/) {$noradsettings->{'NoradSatOnOff'} = $result;}
            elsif ($setting =~ /NoradTleNumbers/) {$noradsettings->{'NoradTleNumbers'} = $result;}
            elsif ($setting =~ /NoradMiscOnOff/) {$noradsettings->{'NoradMiscOnOff'} = $result;}
            elsif ($setting =~ /NoradMiscDetail/) {$noradsettings->{'NoradMiscDetail'} = $result;}
            elsif ($setting =~ /NoradFileName/) {$noradsettings->{'NoradFileName'} = $result;}
        }
            
        elsif ($setting =~ /^Label/) {
            if ($setting =~ /LabelWarningQuake/) {$labelsettings->{'LabelWarningQuake'} = $result;}
            elsif ($setting =~ /LabelWarningVolcano/) {$labelsettings->{'LabelWarningVolcano'} = $result;}
            elsif ($setting =~ /LabelWarningStorm/) {$labelsettings->{'LabelWarningStorm'} = $result;}
            elsif ($setting =~ /LabelWarningNorad/) {$labelsettings->{'LabelWarningNorad'} = $result;}
            elsif ($setting =~ /LabelWarningCloud/) {$labelsettings->{'LabelWarningCloud'} = $result;}
            elsif ($setting =~ /LabelColorOk/) {$labelsettings->{'LabelColorOk'} = $result;}
            elsif ($setting =~ /LabelColorWarn/) {$labelsettings->{'LabelColorWarn'} = $result;}
            elsif ($setting =~ /LabelColorError/) {$labelsettings->{'LabelColorError'} = $result;}
            elsif ($setting =~ /LabelOnOff/) {$labelsettings->{'LabelOnOff'} = $result;}
        }
            
        elsif ($setting =~ /^Easter/) {
            if ($setting =~ /EasterEggSurprises/) {$settings->{'EasterEggSurprises'} = $result;}
        }
            
        elsif ($setting =~ /^Misc/) {
            if ($setting =~ /MiscXplanetVersion1OrBetter/) {$settings->{'XplanetVersion'} = $result;}
        }
            
        elsif ($setting =~ /^Cloud/) {
            if ($setting =~ /CloudRemoteImageName/) {$cloudsettings->{'CloudRemoteImageName'} = $result;}
            elsif ($setting =~ /CloudLocalImageName/) {$cloudsettings->{'CloudLocalImageName'} = $result;}
            elsif ($setting =~ /UseFreeCloudImage/) {$cloudsettings->{'UseFreeCloudImage'} = $result;}
            elsif ($setting =~ /SubcribedToXplanetClouds/) {$cloudsettings->{'SubcribedToXplanetClouds'} = $result;}
            elsif ($setting =~ /CloudUsername/) {$cloudsettings->{'Username'} = $result;}
            elsif ($setting =~ /CloudPassword/) {$cloudsettings->{'Password'} = $result;}
            elsif ($setting =~ /DirectDownload/) {$cloudsettings->{'DirectDownload'} = $result;}
        }
    }
    
    close MF;
}

1; # End of the module
