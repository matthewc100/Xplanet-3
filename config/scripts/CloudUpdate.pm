package CloudUpdate;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use Config::Simple;  # Load the Config::Simple module

use Globals qw($xplanet_images_dir);
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


# CLOUD MIRRORS
my $cloudsettings = {
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
# Returns the name of an internet resource which can provide the clouds image
sub GetRandomMirror() {
    # Populate a list of mirrors
    my @Mirrors;
    if (my $cloudsettings->{'CloudMirrorA'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorA'}";}
    if (my $cloudsettings->{'CloudMirrorB'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorB'}";}
    if (my $cloudsettings->{'CloudMirrorC'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorC'}";}
    if (my $cloudsettings->{'CloudMirrorD'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorD'}";}
    if (my $cloudsettings->{'CloudMirrorE'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorE'}";}
    if (my $cloudsettings->{'CloudMirrorF'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorF'}";}
    if (my $cloudsettings->{'CloudMirrorG'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorG'}";}
    if (my $cloudsettings->{'CloudMirrorH'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorH'}";}
    if (my $cloudsettings->{'CloudMirrorI'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorI'}";}
    if (my $cloudsettings->{'CloudMirrorJ'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorJ'}";}
    if (my $cloudsettings->{'CloudMirrorK'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorK'}";}
    if (my $cloudsettings->{'CloudMirrorL'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorL'}";}
    if (my $cloudsettings->{'CloudMirrorM'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorM'}";}
    if (my $cloudsettings->{'CloudMirrorN'} =~ /\w/) {push @Mirrors, "$cloudsettings->{'CloudMirrorN'}";}
    
    # Return one at random
    return $Mirrors[rand scalar(@Mirrors)];
}

sub cloud_update {
    # my ($url, $file_path) = @_;
    # use the global $xplanet_images_dir value from Globals.pm

# Read credentials from a configuration file
    my $cfg = Config::Simple->new('CloudMap.cfg');
    my $username = $cfg->param('username');
    my $password = $cfg->param('password');
    my $url = $cfg->param('site_link');
    my $file_path = $cfg->param('dest_file_name');

    # Ensure credentials are set
    die "Username and password must be provided" unless $username && $password;

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
        print $fh $response->content; # Use content instead of decoded_content for binary data
        close $fh;
        print "Cloud image downloaded successfully to $xplanet_images_dir as $file_path\n";
#        print "  Updated cloud image as $xplanet_images_dir\\$file_path \n";
    } else {
        die "Failed to download file: " . $response->status_line;
    }
}

1; # End of the module
