# Norad.pm
package Norad;
use strict;
use warnings;
use Exporter 'import';

use Globals qw(
    $noradsettings 
    $xplanet_satellites_dir
    $iss_file
    $isstle_file
 
    $xplanet_images_dir 
    get_webpage
    );

our @EXPORT_OK = qw(
    get_noraddata 
    );

## NORAD SITES
#
# It's important to note what some of the abbreviations mean.  STS, for example is the Space Transportation System
# also called the Space Shuttle.  The Space Shuttle has been retired.  Other items should be added to the list.
# For example Blue Dragon or SpaceX.  Instructions on getting those sites need to be included in a readme file 
# somewhere.  The sts files should be commented out and once I verify everything, I will do that.  
# iss = International Space Station
# css = Chinese Space Station
# hst = Hubble Space Telescope
# sts = Space Transportation System or Space Shuttle, now retired
#


my $iss_location = "https://www.celestrak.com/NORAD/elements/stations.txt";
my $other_locations1 = "https://www.celestrak.com/NORAD/elements/science.txt";
my $hst_location = "https://www.celestrak.com/NORAD/elements/tdrss.txt";
my $sts_location = "https://www.celestrak.com/NORAD/elements/tdrss.txt"; # repeating this line since STS has been retired
my $backup_sat_location = "https://www.idb.com.au/joomla/index.php";

sub get_noraddata {
    # Key Steps
        # Initialize Parameters:
            # $flag: Initially set to 1, assuming that the data retrieval process will proceed unless updated otherwise.
            # $MaxDownloadFrequencyHours: Defines how often (in hours) the system is allowed to download the TLE file.
            # $MaxRetries: Sets the maximum number of retry attempts in case of failure (though this variable isn't used in this subroutine).
        # File Existence Check: 
            # Uses -f to check if the TLE file exists. If it does, the stat function is used to retrieve file metadata, such as the file's last modified time and size.
        # Check File Freshness: 
            # The age of the file is compared to the maximum allowed download frequency (12 hours in this case). If the file is younger than that threshold, it’s 
            # considered up to date, and the flag is set to 3.
        # Download or Check NORAD:
            # If the file is not up to date, the subroutine norad_checked() is called, which is likely responsible for either downloading new data or verifying its 
            # freshness from NORAD.
        # Return Value:
            # The subroutine returns a flag indicating the status of the TLE data retrieval. Depending on the situation, it could return 1 (initial value), 
            # 3 (if up to date), or another value from norad_checked().
            # where the iss and the files will be written to
    my $iss_file = "$xplanet_satellites_dir\\tm";
    my $isstle_file = "$xplanet_satellites_dir\\tm.tle";
    my $flag = 1;  # Initialize the flag, assuming the process will succeed unless conditions change.
    my $MaxDownloadFrequencyHours = 12;  # Maximum allowed time (in hours) between downloads of the TLE file.
    my $MaxRetries = 3;  # Maximum number of retry attempts in case of failure.
    my $tlefile = "$isstle_file";  # The TLE (Two-Line Element) file path for NORAD data (assumed to be set globally).

    # Check if the TLE file exists.
    if (-f $tlefile) {
        my @Stats = stat($tlefile);  # Get file statistics (e.g., last modified time, file size).
        my $FileAge = (time() - $Stats[9]);  # Calculate the age of the file (in seconds) since it was last modified.
        my $FileSize = $Stats[7];  # Get the size of the file in bytes.
        
        # If the file is younger than the maximum download frequency, it's considered up to date.
        if ($FileAge < 60 * 60 * $MaxDownloadFrequencyHours) {
            print "TLEs are up to date!\n";  # Inform the user that the file is up to date.
            $flag = 3;  # Set the flag to 3, indicating that no further download is necessary.
        }
    }
    
    # If the file was not up to date or didn't exist, check NORAD for updates.
    if ($flag != 3) {
        $flag = norad_checked();  # Call a subroutine to check for NORAD updates and potentially download new data.
    } else {
        $flag = "what";  # If the file is up to date, set a placeholder flag (this may be for debugging purposes).
    }
    
    return $flag;  # Return the flag indicating the status of the TLE data retrieval process.
}

sub norad_checked {
    # Key Steps
        # Check NORAD File Name:
        # The subroutine starts by checking if a NORAD file name is provided in the settings. If so, it constructs the file paths for the TLE and ISS files.
    # Download Satellite Data:
        # Data for different satellites (ISS, Hubble, STS, etc.) is downloaded using Globals::get_webpage from various URLs.
        # If the ISS download fails, the subroutine returns "FAILED".
    # Write TLE Data:
        # If data is successfully retrieved, it writes the combined TLE data (ISS, Hubble, and other sources) into the TLE file.
    # Process Satellite Data:
        # It processes the data from different satellites (STS, Soyuz, ISS, Hubble) and writes satellite-specific details, including 
        # their image paths and text descriptions, into the ISS file.
        # It also checks if the required image files exist, and if not, it updates them using update_file().
    # Return Values:
        # Returns "1" for success, "FAILED" for failure, and "what" in other cases.

    # Check if the NORAD file name is provided in the settings
    if ($noradsettings->{'NoradFileName'} =~ /\w+/) {
        # Define file paths for the TLE and ISS files based on the NORAD file name
        $isstle_file = "$xplanet_satellites_dir/$noradsettings->{'NoradFileName'}.tle";
        $iss_file = "$xplanet_satellites_dir/$noradsettings->{'NoradFileName'}";
    }
    
    my $counter = 0;  # Initialize a counter (though unused in this subroutine).
    
    # Download data from various locations (ISS, Hubble, STS, and other satellites).
    my $isstxt = Globals::get_webpage($iss_location);
    my $hsttxt = Globals::get_webpage($hst_location);
    my $ststxt = Globals::get_webpage($sts_location);
    my $otherlocations1txt = Globals::get_webpage($other_locations1);
    
    # If downloading ISS data failed, return "FAILED"
    if ($isstxt eq 'FAILED') {
        return "FAILED";
    } else {
        # Open the TLE file for writing. If it fails, terminate with an error message.
        open my $mf, '>', $isstle_file or die "Cannot open $isstle_file: $!";
        
        # Combine all the downloaded text into one block.
        my $all_tle_data = join("\n", $isstxt, $hsttxt, $otherlocations1txt);
        
        # Split the data by lines.
        my @lines = split("\n", $all_tle_data);
        
        # Process the TLE data in chunks of three lines (name, TLE line 1, TLE line 2).
        for (my $i = 0; $i <= $#lines; $i++) {
            # Remove any leading or trailing whitespace on each line
            $lines[$i] =~ s/^\s+|\s+$//g;

            # Check if the current line is a satellite name (not starting with '1' or '2').
            if ($lines[$i] !~ /^[12]\s/) {
                # Print the satellite name followed by its two TLE lines.
                print $mf "$lines[$i]\n";      # Satellite name.
                print $mf "$lines[$i + 1]";    # First TLE line.
                print $mf "$lines[$i + 2]";    # Second TLE line.

                # Skip the next two lines, as they've already been processed.
                $i += 2;
            }
        }
        
        close $mf;  # Close the TLE file after writing the data.
        
        # Open the ISS file for writing.
        open $mf, '>', $iss_file or die "Cannot open $iss_file: $!";
        
        # Initialize variables to track different satellite types.
        my $TLEline = 0;
        my ($stsyes, $soyuzyes, $unknown) = (0, 0, 0);
        
        # Process the STS data to look for STS, Hubble, Soyuz, or unknown satellites.
        if ($ststxt !~ /</) {
            foreach (split("\n", $ststxt)) {
                my @values = split;  # Split the line into values.
                
                # Reset the TLE line counter every 3 lines (as TLE data is 3 lines per satellite).
                if ($TLEline == 3) { $TLEline = 0; }
                
                # Identify the satellite type based on the first value.
                if ($TLEline == 0) {
                    if ($values[0] =~ /STS/) { $stsyes = 1; }
                    elsif ($values[0] =~ /HST|ISS/) { $unknown = 0; }
                    elsif ($values[0] =~ /SOYUZ/) { $soyuzyes = 1; }
                    else { $unknown = 1; }
                }
                
                # Write STS satellite information to the file if found.
                if ($stsyes && $TLEline == 2) {
                    my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradStsImage'};
                    -e $file || update_file('STS');  # Check if the image file exists, otherwise update it.
                    if ($noradsettings->{'NoradStsOnOff'} =~ /On/) {
                        print $mf "$values[1] \"$noradsettings->{'NoradStsText'}\" image=$noradsettings->{'NoradStsImage'} $noradsettings->{'NoradStsDetail'}\n";
                    }
                    $stsyes = 0;  # Reset the STS flag after writing.
                }
                
                # Write information for unknown satellites.
                elsif ($unknown && $TLEline == 2) {
                    my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradSatImage'};
                    -e $file || update_file('SAT');  # Check if the image file exists, otherwise update it.
                    if ($noradsettings->{'NoradSatOnOff'} =~ /On/) {
                        print $mf "$values[1] \"$noradsettings->{'NoradSatText'}\" image=$noradsettings->{'NoradSatImage'} $noradsettings->{'NoradSatDetail'}\n";
                    }
                    $unknown = 0;  # Reset the unknown flag after writing.
                }
                
                $TLEline++;  # Increment the TLE line counter.
            }
        }
        
        # Process ISS and Soyuz satellite data if the ISS data is valid.
        if ($isstxt !~ /</) {
            foreach (split("\n", $isstxt)) {
                my @values = split;
                
                # Reset the TLE line counter every 3 lines.
                if ($TLEline == 3) { $TLEline = 0; }
                
                # Identify Soyuz satellites and write their information to the file.
                if ($TLEline == 0 && $values[0] =~ /SOYUZ/) { $soyuzyes = 1; }
                if ($soyuzyes && $TLEline == 2) {
                    my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradSoyuzImage'};
                    -e $file || update_file('SOYUZ');  # Check if the image file exists, otherwise update it.
                    if ($noradsettings->{'NoradSoyuzOnOff'} =~ /On/) {
                        print $mf "$values[1] \"$noradsettings->{'NoradSoyuzText'}\" image=$noradsettings->{'NoradSoyuzImage'} $noradsettings->{'NoradSoyuzDetail'}\n";
                    }
                    $soyuzyes = 0;  # Reset the Soyuz flag after writing.
                }
                $TLEline++;  # Increment the TLE line counter.
            }
        }
        
        # Write ISS information to the file if the ISS feature is enabled.
        my $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradIssImage'};
        -e $file || update_file('ISS');
        if ($noradsettings->{'NoradIssOnOff'} =~ /On/) {
            print $mf "25544 \"$noradsettings->{'NoradIssText'}\" image=$noradsettings->{'NoradIssImage'} $noradsettings->{'NoradIssDetail'}\n";
        }
        
        # Write Hubble Space Telescope (HST) information if the HST feature is enabled.
        $file = $xplanet_images_dir . '/' . $noradsettings->{'NoradHstImage'};
        -e $file || update_file('HST');
        if ($noradsettings->{'NoradHstOnOff'} =~ /On/) {
            print $mf "20580 \"$noradsettings->{'NoradHstText'}\" image=$noradsettings->{'NoradHstImage'} $noradsettings->{'NoradHstDetail'}\n";
        }
        
        # Write miscellaneous NORAD satellite information if enabled.
        if ($noradsettings->{'NoradMiscOnOff'} =~ /On/) {
            my @tmp = split " ", $noradsettings->{'NoradTleNumbers'};
            for my $num (@tmp) {
                if ($num =~ /\d{5}/) {  # Check for valid TLE numbers (5 digits).
                    print $mf "$num \"\" image=$num.gif $noradsettings->{'NoradMiscDetail'}\n";
                }
            }
        }
        
        close $mf;  # Close the ISS file after all data is written.
        return "1";  # Return success status.
    }
    
    return "what";  # Default return value if no action was taken.
}



sub update_file {
    # Explanation:
        # Satellite Type: The subroutine takes a satellite type (e.g., ISS, HST) as an argument and assigns the appropriate default image file name 
        # based on the type.

        # File Path Construction: It constructs the file path for the image file by combining the xplanet_images_dir directory with the image file 
        # name stored in $noradsettings.

        # Check and Download: It checks if the image file exists on disk using -e. If the file does not exist, it calls the get_file subroutine to 
        #download the image from a URL.

    my ($type) = @_;  # Accepts the satellite type as an argument (e.g., ISS, HST, STS, etc.).

    # Assigns default image names based on the type of satellite.
    if ($type eq 'ISS') {
        $noradsettings->{'NoradIssImage'} = 'iss.png';  # Set ISS image name.
    } elsif ($type eq 'HST') {
        $noradsettings->{'NoradHstImage'} = 'hst.png';  # Set HST image name.
    } elsif ($type eq 'STS') {
        $noradsettings->{'NoradStsImage'} = 'sts.png';  # Set STS image name.
    } elsif ($type eq 'SAT') {
        $noradsettings->{'NoradSatImage'} = 'sat.png';  # Set generic satellite image name.
    } elsif ($type eq 'SOYUZ') {
        $noradsettings->{'NoradSoyuzImage'} = 'soyuz.png';  # Set Soyuz image name.
    }
    
    # Construct the full file path for the image based on the type.
    my $file = $xplanet_images_dir . '/' . $noradsettings->{"Norad${type}Image"};

    # Check if the image file exists. If not, call get_file() to download it.
    -e $file || get_file($noradsettings->{"Norad${type}Image"});
}


sub get_file {
    # Explanation:
        # File and URL Construction:
            # The subroutine constructs the URL to download the image file from the provided satellite image repository.
            # It also builds the output file path where the image will be saved in the local directory.
        # Download the File:
            # It calls get_webpage() to retrieve the content of the file from the URL. If the content is retrieved successfully (i.e., not undef), 
            # it proceeds to save the file locally.
        # Save the File:
            # The image is saved to the specified directory using binary mode (binmode) to ensure the data is written correctly.
        # Error Handling:
            # If the file is not downloaded successfully (undef content), no further actions are taken.
    my ($file) = @_;  # Accepts the file name as an argument (e.g., 'iss.png').

    # Construct the URL from which to download the image file.
    my $gif_URL = "http://www.wizabit.eclipse.co.uk/xplanet/files/local/images/$file";

    # Extract the file name and extension (e.g., 'iss' and 'png').
    my ($name, $ext) = split '\.', $file, 2;

    # Construct the output file path where the image will be saved.
    my $outfile = "$xplanet_images_dir/$file";
    
    # Retrieve the content of the webpage or file from the URL.
    my $content = get_webpage($gif_URL);

    # If the content is successfully retrieved (not undefined), write it to the file.
    if ($content eq undef) {
        # Do nothing if content is not retrieved.
    } else {
        # Open the output file for writing in binary mode.
        open(IMAGE, ">$outfile");
        binmode IMAGE;  # Ensure binary data is written correctly.
        
        # Write the downloaded content to the output file.
        print IMAGE $content;
        
        # Close the file handle after writing.
        close(IMAGE);
    }
}



1;
