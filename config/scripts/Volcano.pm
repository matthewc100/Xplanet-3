package Volcano;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    WriteoutVolcano
    get_volcanodata
    volcanodata_checked
);

use Globals qw($volcano_marker_file $volcanosettings get_webpage);

## VOLCANO SITES
# I don't know much about these sites yet.  This should be another readme file after the research is done.  
my $volcano_location = "https://volcano.si.edu/news/WeeklyVolcanoCAP.xml";

sub WriteoutVolcano {
    # 26 September 2024
    # Key Modifications:
        # The filehandle VOLCANO_FH is passed to Label::file_header
    # Error Handling for File Operations:
        # Added or die for the file opening operation to ensure the script stops if the file cannot be opened, and or warn for file closing to provide warnings 
        # in case closing fails
    # Consistent Filehandle Usage:
        # The filehandle VOLCANO_FH is used in all print and printf statements instead of the generic MF
    # Added inline comments to explain each part of the subroutine and the logic behind processing active volcano data
    my ($counter) = @_;  # Argument for the number of volcano entries to process.
    my $recounter = 0;   # Initialize recounter for looping through volcano entries.
    my $volcanosettings; # Settings for volcano configuration (assumed populated elsewhere).
    my @volcanodata;     # Array to hold volcano data (assumed populated elsewhere).
    my $locations;       # Variable for volcano locations (assumed populated elsewhere).

    # Check if the counter is valid and not set to "FAILED".
    if ($counter !~ /FAILED/) {
        my $openfile = 'Volcano';  # Set the open file name for the header.

        # Open the volcano marker file for writing, with error handling.
        open (VOLCANO_FH, ">$volcano_marker_file") or die "Cannot open $volcano_marker_file: $!";

        # Pass the filehandle (VOLCANO_FH) to Label::file_header for writing the header.
        Label::file_header($openfile, *VOLCANO_FH);

        # Loop through each volcano entry and write its data to the file.
        while ($recounter < $counter) {
            # Extract volcano data for the current recounter index.
            my $long = $volcanodata[$recounter]->{'long'};
            my $lat = $volcanodata[$recounter]->{'lat'};
            my $name = $volcanodata[$recounter]->{'name'};
            my $elev = $volcanodata[$recounter]->{'elev'};

            # Format latitude and longitude with two decimal places.
            $lat  = sprintf("% 8.2f", $lat);
            $long = sprintf("% 9.2f", $long);

            # Print inner and middle circle markers for the volcano.
            print VOLCANO_FH "$lat $long \"\" color=$volcanosettings->{'VolcanoCircleColorInner'} symbolsize=$volcanosettings->{'VolcanoCircleSizeInner'}\n";
            print VOLCANO_FH "$lat $long \"\" color=$volcanosettings->{'VolcanoCircleColorMiddle'} symbolsize=$volcanosettings->{'VolcanoCircleSizeMiddle'}\n";

            # If volcano names are enabled in the settings, print the volcano name with alignment and color settings.
            if ($volcanosettings->{'VolcanoNameOnOff'} =~ /On/) {
                if ($volcanosettings->{'VolcanoImageList'} =~ /\w/) {
                    print VOLCANO_FH "$lat $long \"$name\" align=$volcanosettings->{'VolcanoNameAlign'} color=$volcanosettings->{'VolcanoNameColor'} image=$volcanosettings->{'VolcanoImageList'} ";
                    
                    # If transparency for images is enabled, add the transparency setting.
                    if ($volcanosettings->{'VolcanoImageTransparent'} =~ /\d/) {
                        print VOLCANO_FH "transparent=$volcanosettings->{'VolcanoImageTransparent'}";
                    }
                } else {
                    # If no image is specified, print the volcano name with circle and alignment settings.
                    print VOLCANO_FH "$lat $long \"$name\" color=$volcanosettings->{'VolcanoCircleColorOuter'} symbolsize=$volcanosettings->{'VolcanoCircleSizeOuter'} align=$volcanosettings->{'VolcanoNameAlign'}";
                }
            } else {
                # Print the outer circle for the volcano if names are not enabled.
                print VOLCANO_FH "$lat $long \"\" color=$volcanosettings->{'VolcanoCircleColorOuter'} symbolsize=$volcanosettings->{'VolcanoCircleSizeOuter'}";
            }

            # Move to the next line after writing the volcano marker.
            print VOLCANO_FH "\n";

            # If volcano details are enabled in the settings, write the detailed data.
            if ($volcanosettings->{'VolcanoDetailList'} =~ /\w/) {
                my $tmp1 = $volcanosettings->{'VolcanoDetailList'};
                
                # Replace placeholders with actual volcano data.
                $tmp1 =~ s/<lat>/$lat/g;
                $tmp1 =~ s/<long>/$long/g;
                $tmp1 =~ s/<elevation>/$elev/g;
                $tmp1 =~ s/<elev>/$elev/g;
                $tmp1 =~ s/<name>/$name/g;
                $tmp1 =~ s/<location>/$locations/g;

                # Print the volcano detail data with alignment and color settings.
                print VOLCANO_FH "$lat $long \"$tmp1\" color=$volcanosettings->{'VolcanoDetailColor'} align=$volcanosettings->{'VolcanoDetailAlign'} image=none\n";
            }

            # Increment recounter to process the next volcano entry.
            $recounter++;
        }

        # Close the file after writing all data, with error handling.
        close VOLCANO_FH or warn "Could not close $volcano_marker_file: $!";
    }
}


sub get_volcanodata {
    my $flag = 1;
    my $MaxDownloadFrequencyHours = 24;
    my $MaxRetries = 3;
    my $volcanodata_file = "$volcano_marker_file";

    if (-f $volcanodata_file) {
        my @Stats = stat($volcanodata_file);
        my $FileAge = (time() - $Stats[9]);
        my $FileSize = $Stats[7];

        if ($FileAge < 60 * 60 * $MaxDownloadFrequencyHours) {
            print "Volcano data is up to date!\n";
            $flag = 0;
        }
    }

    if ($flag != 0) {
        $flag = volcanodata_checked();
    } else {
        $flag = "what";
    }

    return $flag;
}

sub volcanodata_checked {
    my $volcanotxt;
    my $counter = 0;
    my $detail;
    my $elev;
    my @volcanodata;

    $volcanotxt = get_webpage($volcano_location);

    if ($volcanotxt !~ /FAILED/) {
        $volcanotxt =~ s/[\r\n]+//g;

        foreach (split("<info>", $volcanotxt)) {
            chomp;

            if (/.*\<valueName\>Volcano Name\<\/valueName\>\<value\>([A-Z,\s]+)\<\/value\>.*\<areaDesc\>([A-Z,\-,\s]+)\<\/areaDesc\>\<circle\>([\d\-\.]+),([\d\-\.]+).[\d\-\.]+\<\/circle\>.*/i) {
                my ($name, $area, $lat, $long) = ($1, $2, $3, $4);

                $elev = "UNKNOWN";

                if ($detail =~ /(\d+\.\d+)&deg;([NS])/) {
                    my $sign;
                    ($lat, $sign) = ($1, $2);
                    $lat *= ($sign =~ /s/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)&deg;([EW])/) {
                    my $sign;
                    ($long, $sign) = ($1, $2);
                    $long *= ($sign =~ /w/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)\x{00B0}([NS])/) {
                    my $sign;
                    ($lat, $sign) = ($1, $2);
                    $lat *= ($sign =~ /s/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)&#176([NS])/) {
                    my $sign;
                    ($lat, $sign) = ($1, $2);
                    $lat *= ($sign =~ /s/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)\x{00B0}([EW])/) {
                    my $sign;
                    ($long, $sign) = ($1, $2);
                    $long *= ($sign =~ /w/i) ? -1 : 1;
                }

                if ($detail =~ /(\d+\.\d+)&#176([EW])/) {
                    my $sign;
                    ($long, $sign) = ($1, $2);
                    $long *= ($sign =~ /w/i) ? -1 : 1;
                }

                if ($detail =~ /summit elev\..*?([\d,]+)/) {
                    $elev = $1;
                    $elev =~ s/\D//;
                    $elev *= 1;
                }

                $name =~ s/\&(.).*?\;/lc($1)/eg;
                $name = lc($name);
                $name =~ s/\b(\w)/uc($1)/eg;

                if ($name !~ /Additional/) {
                    push @volcanodata, {
                        'lat' => $lat,
                        'long' => $long,
                        'name' => $name,
                        'elev' => $elev,
                        'location' => $area,
                    };
                    $counter++;
                }
            }
        }

        print "  Updated volcano information\n";
        return $counter;
    } else {
        print "  WARNING... unable to access or download updated volcano information\n";
        return $volcanotxt;
    }
}

1; # End of the module
