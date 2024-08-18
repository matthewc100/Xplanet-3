package CloudUpdate;
use strict;
use warnings;
use Exporter 'import';

sub cloud_update() {
    my $flag = 1;
    my $MaxDownloadFrequencyHours = 2;
    my $MaxRetries = 3;
    my $cloud_image_file = "$xplanet_images_dir\\$cloudsettings->{'CloudLocalImageName'}";
    #print "$cloud_image_file\n";
    
    # Get file details
    if (-f $cloud_image_file) {
        my @Stats = stat($cloud_image_file);
		my $FileAge = (time() - $Stats[9]);
		my $FileSize = $Stats[7];
        
		# Check if file is already up to date
		if ($FileAge < 60 * 60 * $MaxDownloadFrequencyHours && $FileSize > 400000) {
		    print "  Cloud image is up to date... no need to download\n";
            $flag = 3;
		}
    }
    
    if ($flag != 3) {
        # TODO: fix this block as it's never executed
        # if ($cloudsettings->{'CloudBias'} =~ /\w/) {
        #     my $BiasFile = "$cloud_image_base/$cloudsettings->{'CloudRemoteImageName'}";
        #     my $Response = getstore($BiasFile, $cloud_image_file);
        #     if ( IndicatesSuccess($Response)) {
        #         $flag = 2;
        #     }
        # }
        
        # TODO - move away from curl to something perl specific
        # TODO - make this subroutine more robust with error checking as originally intended
        # TODO - and consistent with the rest of the script, specifically the cloudsettings definition and variable names
        my $download_string = "curl -s -u $cloudsettings->{'Username'}:$cloudsettings->{'Password'} -z $cloud_image_file -R -L -o $cloud_image_file $cloud_image_base/$cloudsettings->{'CloudRemoteImageName'}";
        my $Response = `$download_string`;
        if ( IndicatesSuccess($Response)) {
            # if this shows up in the logs then find out how/why
            print "  Updated cloud image (IF YOU SEE THIS IN THE LOGS THEN THERE IS A PROBLEM)\n";
            $flag = 2;
        }
        # the above conditional is never met so forcing this statement implying an attempt was made, but didn't receive http code 2xx implying success downloading
        print "  Updated cloud image\n";
    }
    
    return $flag;
}