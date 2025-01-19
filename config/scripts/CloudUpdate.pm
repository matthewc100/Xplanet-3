package CloudUpdate;
use strict;
use warnings;
use LWP::UserAgent;
use Time::Local; 
use HTTP::Request::Common;
use Config::Simple;  # Load the Config::Simple module

use Globals qw(
    $xplanet_images_dir 
    %modules
    $cloudsettings 
    $label_file
    );
use Exporter 'import';
our @EXPORT_OK = qw(cloud_update); 

#################################################
#  Notes                                        #
#################################################
# The CloudUpdate module used to be able to obtain cloud images from a variety of locations
# across the web.  These locations would be listed in the Cloud Mirror settings section, below.
# Alas, I haven't found any free locations of the fully stitched cloud images we can use
# for Xplanet on earth.  I only know about the cloud images for sale via Xeric.  
#
# INPUTS TO CLOUDUPDATE
# Setting aside the Cloud Mirror idea for now, this routine expects three inputs:
#   $URL = this is used to define the web location of the file to be downloaded
#   $file_path = this is the name of the file in the images (destination) directory.  
#   $xplanet_images_dir = the location of the images directory, a global variable defined in Globals.pm
#
# OUTPUT
# CLOUDUPDATE writes a new cloud image file to the images directory, and announces success with a print line
#
# The module expects to find a CloudMap.cfg file in the /config/scripts directory that contains
# the userid and password to the cloud image source site.  See CloudMap-template.cfg for an 
# example.  

# Example usage of CloudUpdate module
# my $cloud_image_url = "http://secure.xericdesign.com/xplanet/clouds/8192/clouds-8192.jpg";
# my $cloud_file_name = "clouds-8192.jpeg";

## CLOUD SITES
# I don't know much about these sites yet.  This should be another readme file after the research is done.
# I get my cloud image from the Xeric guys.  Note that the credentials for downloading the cloud map are 
# privatized in a separate file.  This file is maintained by the user.  There is a .gitignore setting for 
# this credential file to ensure it is not uploaded to Git.  I'll have to create a readme for that.  
my $cloud_image_base = "https://secure.xericdesign.com/xplanet/clouds/4096";
# my $cloud_image_base = "https://xplanetclouds.com/free/coral/";
#

sub cloud_update {
    # Read credentials from the configuration file
    my $cfg = Config::Simple->new('CloudMap.cfg');
    my $username = $cfg->param('username');
    my $password = $cfg->param('password');
    my $url = $cfg->param('site_link');
    my $file_path = $cfg->param('dest_file_name');

    my $max_frequency_hours = $Globals::modules{'clouds'}{'Max.Download.Frequency.Hours'} // 6;
    if (!defined $Globals::modules{'clouds'}{'Max.Download.Frequency.Hours'}) {
        warn "Max.Download.Frequency.Hours is undefined. Check configuration or .ini file.";
    }

    # Step 1: Check if an update is needed
    unless (should_update_cloud_map($max_frequency_hours)) {
        print "Skipping cloud map update: too frequent\n";
        print "Cloud map expected at: $xplanet_images_dir\\$file_path\n";  # Include the full path
        return;
    }

    # Ensure credentials are set
    die "Username and password must be provided" unless $username && $password;

    # Step 2: Proceed with downloading the cloud map
    print "Downloading cloud map...\n";

    # Create a user agent object
    my $ua = LWP::UserAgent->new;

    # Create an HTTP request with basic authentication
    my $request = GET $url;
    $request->authorization_basic($username, $password);

    # Perform the request
    my $response = $ua->request($request);

    # Check if the request was successful
    if ($response->is_success) {
        # Open the file for writing in binary mode
        open my $fh, '>:raw', "$xplanet_images_dir\\$file_path" or die "Could not open file '$xplanet_images_dir\\$file_path': $!";
        print $fh $response->content; # Use content for binary data
        close $fh;
        print "Cloud image downloaded successfully to $xplanet_images_dir as $file_path\n";
    } else {
        die "Failed to download file: " . $response->status_line;
    }
}

# Subroutine to check if we should update the cloud map
sub should_update_cloud_map {
    my ($max_frequency_hours) = @_;

    # Get the cloud map file name from the settings
    my $file_name = $Globals::modules{'clouds'}{'Cloud.Local.Image.Name'} // 'clouds-8192.jpg';

    # Full path to the expected cloud map file
    my $cloud_file = "$xplanet_images_dir\\$file_name";

    # Debug: Print the file path being checked
    print "Debug: Checking existence of cloud map file: $cloud_file\n";

    # Check if the cloud map file exists
    unless (-e $cloud_file) {
        print "Cloud map file does not exist: $cloud_file\n";
        return 1;  # Trigger update if the file is missing
    }

    # Check the last update time in the label file
    my $last_update_time = get_last_update_time("Cloud");

    # Debug: Check if last update time is retrieved
    print "Debug: Last update time retrieved: " . (defined $last_update_time ? localtime($last_update_time) : "undef") . "\n";

    # Debug: Current time
    my $current_time = time();
    print "Debug: Current time: " . localtime($current_time) . "\n";

    # If last update time exists, calculate elapsed time
    if (defined $last_update_time) {
        my $elapsed_time = $current_time - $last_update_time;

        # Debug: Print elapsed time and max frequency
        print "Debug: Elapsed time since last update: $elapsed_time seconds\n";
        print "Debug: Max frequency (hours): $max_frequency_hours\n";

        if ($elapsed_time < $max_frequency_hours * 3600) {
            print "Cloud data is up to date (last updated: " . localtime($last_update_time) . ")\n";
            return 0;  # No update needed
        }
    }

    # If no recent data or outdated, return true to update
    return 1;
}



# Subroutine to get the last update time for a type from the label file
sub get_last_update_time {
    my ($type) = @_;
    return undef unless -e $label_file;

    print "Debug: Checking last update time in $label_file for type: $type\n";

    open(my $fh, '<', $label_file) or die "Cannot open $label_file: $!";
    while (<$fh>) {
        print "Debug: Line read: $_";  # Debug each line read
        if (/\b$type\b.*last updated.*?(\d{2}-\w{3}-\d{4} \d{2}:\d{2})/) {
            my $timestamp_str = $1;

            # Debug: Print the extracted timestamp
            print "Debug: Extracted timestamp: $timestamp_str\n";

            close $fh;
            return convert_to_epoch($timestamp_str);
        }
    }
    close($fh);
    print "Debug: No matching timestamp found for type: $type\n";
    return undef;
}


# Helper to convert a timestamp string to epoch time
sub convert_to_epoch {
    my ($timestamp_str) = @_;
    print "Debug: Converting timestamp: $timestamp_str\n";

    if ($timestamp_str =~ /(\d{2})-(\w{3})-(\d{4}) (\d{2}):(\d{2})/) {
        my ($day, $mon_str, $year, $hour, $min) = ($1, $2, $3, $4, $5);

        # Debug: Print extracted components
        print "Debug: Extracted components - Day: $day, Month: $mon_str, Year: $year, Hour: $hour, Minute: $min\n";

        my %months = (
            Jan => 0,  Feb => 1,  Mar => 2,  Apr => 3,  May => 4,  Jun => 5,
            Jul => 6,  Aug => 7,  Sep => 8,  Oct => 9,  Nov => 10, Dec => 11
        );
        my $mon = $months{$mon_str};

        return timelocal(0, $min, $hour, $day, $mon, $year - 1900);
    }

    print "Debug: Failed to parse timestamp: $timestamp_str\n";
    return undef;
}


1; # End of the module
