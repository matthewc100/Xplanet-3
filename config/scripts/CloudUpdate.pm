package CloudUpdate;
use strict;
use warnings;
use LWP::UserAgent;
use Time::Local; 
use HTTP::Request::Common;
use Config::Simple;  # Load the Config::Simple module

use Globals qw($xplanet_images_dir $cloudsettings $label_file);
use Exporter 'import';
our @EXPORT_OK = qw(cloud_update); # is this line needed?  

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

    my $MaxDownloadFrequencyHours = $cloudsettings->{'MaxDownloadFrequencyHours'} // 6; # Default to 6 hours if not defined
    if (!defined $MaxDownloadFrequencyHours) {
        warn "MaxDownloadFrequencyHours is undefined. Check configuration or initialization.";
    }

    # Step 1: Check if we need to update the cloud map
    if (!should_update_cloud_map($MaxDownloadFrequencyHours)) {
        print "Skipping cloud map update: too frequent\n";
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
     my ($MaxDownloadFrequencyHours) = @_;

    # Check the last update time for Cloud in updatelabel
    my $last_update_time = get_last_update_time("Cloud");

    # If the data is recent enough, skip the update
    if (defined $last_update_time) {
        my $current_time = time();
        my $elapsed_time = $current_time - $last_update_time;
        if (!defined $MaxDownloadFrequencyHours) {
            warn "MaxDownloadFrequencyHours is undefined. Check configuration or initialization.";
        }
        if ($elapsed_time < $MaxDownloadFrequencyHours * 3600) {
            print "Cloud data is up to date (last updated: " . localtime($last_update_time) . ")\n";
            return 0; # No update needed
        }
    }

    # If no recent data or outdated, return true to update
    return 1;
}

# Subroutine to get the last update time for a type from the label file
sub get_last_update_time {
    my ($type) = @_;
    return undef unless -e $label_file;

    open(my $fh, '<', $label_file) or die "Cannot open $label_file: $!";
    while (<$fh>) {
        if (/\b$type\b.*last updated.*?(\d{2}-\w{3}-\d{4} \d{2}:\d{2})/) {
            my $timestamp_str = $1;
            close $fh;

            # Convert the timestamp to epoch time
            my $epoch_time = convert_to_epoch($timestamp_str);
            return $epoch_time;
        }
    }
    close($fh);
    return undef;
}

# Helper to convert a timestamp string to epoch time
sub convert_to_epoch {
    my ($timestamp_str) = @_;
    if ($timestamp_str =~ /(\d{2})-(\w{3})-(\d{4}) (\d{2}):(\d{2})/) {
        my ($day, $mon_str, $year, $hour, $min) = ($1, $2, $3, $4, $5);
        my %months = (
            Jan => 0,  Feb => 1,  Mar => 2,  Apr => 3,  May => 4,  Jun => 5,
            Jul => 6,  Aug => 7,  Sep => 8,  Oct => 9,  Nov => 10, Dec => 11
        );
        my $mon = $months{$mon_str};
        return timelocal(0, $min, $hour, $day, $mon, $year - 1900);
    }
    return undef;
}

1; # End of the module
