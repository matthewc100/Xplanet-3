package Hurricane;
use strict;
use warnings;
use Globals qw(
    $stormsettings
    $hurricane_arc_file
    $hurricane_marker_file
    );
use Exporter 'import';
our @EXPORT_OK = qw($hurricane_record_number); # is this line needed?  

## STORMS AND HURRICANES
# 
# The sites listed here have gone dark and the data doesn't exist in the same form it once did.
# This state of affairs is one of the reasons for refactoring the TotalMarker script into modules. 
# Updating and maintaining the script should be be easier once it's modular.  
#
my $storm_base_location = "https://www.nrlmry.navy.mil/tcdat/sectors/ftp_sector_file";
my $storm_past_location = "https://www.nrlmry.navy.mil/archdat/test/kml/TC/";
my $storm_future_location = "https://www.nrlmry.navy.mil/atcf_web/docs/current_storms/";

sub get_hurricane_data_count {
    my $hurricane_counter = 0;
    my $hurricanetxt;
    my $sign;
    my $year;
    my $type;
    my $ocean;
    my $file;
    my $hurricanetotallist;
    my @hurricanearcdataact;
    my @hurricanearcdatafor;
    my @hurricanedata;
    
    $hurricanetotallist = get_webpage($storm_base_location);
    
    if ($hurricanetxt !~ /FAILED/) {
        foreach (split("\n",$hurricanetotallist)) {
            if (/([\d\w]+)\s(\w+)\s(\d+)\s(\d+)\s+([\d\-\.NS]+)\s+([\d\-\.EW]+)\s(\w+)\s+(\d+)\s+(\d+)/) {
                my($code,$name,$date,$time,$lat,$long,$location,$speed,$detail)=($1,$2,$3,$4,$5,$6,$7,$8,$9);
                if ($lat =~ /(\d+\.\d+)([NS])/) {
                    ($lat,$sign)=($1,$2);
                    $lat *= -1 if $sign =~ /s/i;
                }
                $lat *= 1;
                
                if ($long =~ /(\d+\.\d+)([WE])/) {
                    ($long,$sign)=($1,$2);
                    $long *= -1 if $sign =~ /w/i;
                }
                $long *= 1;
                $speed =~ s/^0+//;
                
                if ($name =~ /INVEST/) {
                    $type = "DEP";
                    $name = $code;
                }
                else {
                    $type = "STO";
                }
                
                $year = "20".substr $date,0,2;
                
                if ($location =~ /ATL/) {
                    $ocean = "al";
                }
                elsif ($location =~ /WPAC/) {
                    $ocean = "wp";
                }
                elsif ($location =~ /EPAC/) {
                    $ocean = "ep";
                }
                elsif ($location =~ /CPAC/) {
                    $ocean = "cp";
                }
                
                push @hurricanedata, {
                    'type'  => $type,
                    'file'  => $file,
                    'name'  => $name,
                    'lat'   => $lat,
                    'long'  => $long,
                    'speed' => $speed,
                    'code'  => $code,
                    'year'  => $year,
                    'ocean' => $ocean,
                    'loc'   => $location,
                };
            }
            
            $hurricane_counter++;
        }
        
        if ($hurricane_counter == 0) {
            print "  ERROR (-1)?... Unable to parse storm information\n";
            return -1;
        }
        else {
            print "  Updated storm information\n";
            return $hurricane_counter;
        }
    }
    else {
        print "  WARNING... unable to access or download updated storm information\n";
        return $hurricanetxt;
    }
}

sub get_hurricanearcdata {
    my ($hurricane_counter) = @_;
    my $recounter = 0;
    my $forcounter = 0;
    my $actcounter = 0;
    my $storm_track;
    my $temp_chop;
    my @hurricanedata;
    my @hurricanearcdataact;
    my @hurricanearcdatafor;
    my $sign;
    
    if ($hurricane_counter != 'FAILED') {
        while ($recounter < $hurricane_counter) {
            my $storm_past = get_webpage($storm_past_location.$hurricanedata[$recounter]->{'year'}."/".$hurricanedata[$recounter]->{'loc'}."/".$hurricanedata[$recounter]->{'code'}."/trackfile.txt");
            
            if ($storm_track !~ /FAILED/) {
                foreach (split("\n",$storm_past)) {
                    if (/([\d\w]+)\s(\w+)\s(\d+)\s(\d+)\s+([\d\-\.NS]+)\s+([\d\-\.EW]+)\s(\w+)\s+(\d+)\s+(\d+)/) {
                        my($code,$name,$date,$time,$lat,$long,$location,$speed,$detail)=($1,$2,$3,$4,$5,$6,$7,$8,$9);
                        
                        if ($lat =~ /(\d+\.\d+)([NS])/) {
                            ($lat,$sign)=($1,$2);
                            $lat *= -1 if $sign =~ /s/i;
                        }
                        $lat *= 1;
                        
                        if ($long =~ /(\d+\.\d+)([WE])/) {
                            ($long,$sign)=($1,$2);
                            $long *= -1 if $sign =~ /w/i;
                        }
                        
                        $long *= 1;
                        
                        push @hurricanearcdataact, {
                            'num'   => $recounter,
                            'lat'   => $lat,
                            'long'  => $long,
                            'name'  => $name,
                        };
                        
                        $actcounter++;
                    }
                }
            }
            
            $recounter++;
        }
        
        $recounter = 0;
        while ($recounter < $hurricane_counter) {
            $temp_chop = chop($hurricanedata[$recounter]->{'code'});
            $temp_chop = $storm_future_location.$hurricanedata[$recounter]->{'ocean'}.$hurricanedata[$recounter]->{'code'}.$hurricanedata[$recounter]->{'year'}.".tcw\n";
            $storm_track = get_webpage($temp_chop);
            
            if ($storm_track !~ /FAILED/) {
                foreach (split("\n",$storm_track)) {
                    if (/(T\d{3})\s(\d{3,4}\w)\s(\d{3,4}\w)\s\d{3}/) {
                        my($time,$lat,$long)=($1,$2,$3);
                        
                        if ($lat =~ /(\d+)([NS])/) {
                            ($lat,$sign)=($1,$2);
                            $lat *= -1 if $sign =~ /s/i;
                        }
                        $lat *= 0.1;
                        
                        if ($long =~ /(\d+)([WE])/) {
                            ($long,$sign)=($1,$2);
                            $long *= -1 if $sign =~ /w/i;
                        }
                        $long *= 0.1;
                        
                        push @hurricanearcdatafor, {
                            'num'   => $recounter,
                            'lat'   => $lat,
                            'long'  => $long,
                        };
                        
                        $forcounter++;
                    }
                }
            }
        
        $recounter++;
        }
        
        print "  Updated storm arc information\n";
    }
    else {
        $actcounter = 'FAILED';
        $forcounter = 'FAILED';
        print "  WARNING... unable to access or download updated storm arc information\n";
    }
    
    return $actcounter,$forcounter;
}

sub WriteoutHurricaneArc {
    # 26 September 2024
    # Key Modifications:
        # The filehandle HURRICANE_FH is passed to Label::file_header
    # Error Handling for File Operations:
        # Added or die for the file opening operation to ensure the script stops if the file cannot be opened, and or warn for file closing to provide warnings 
        # in case closing fails
    # Consistent Filehandle Usage:
        # The filehandle HURRICANE_FH is used in all print and printf statements instead of the generic MF
    # Added inline comments to explain each part of the subroutine and the logic behind processing active and forecasted hurricane tracks

    my ($numhur, $numact, $numfor) = @_;  # Arguments for the number of hurricanes, active and forecasted tracks.
    my $counter = 0;                      # Initialize a counter for the loops.
    my $recounter = 0;                    # Initialize recounter for tracking storm data changes.
    my $stormsettings;                    # Settings for storm tracking (assumed to be populated elsewhere).
    my @hurricanearcdataact;              # Array to hold active hurricane arc data.
    my @hurricanearcdatafor;              # Array to hold forecasted hurricane arc data.
    
    # Check for failure conditions in the input arguments.
    if ($numhur =~ /FAILED/) {
        # Do nothing if hurricane data is marked as failed.
    } elsif ($numact =~ /FAILED/) {
        # Do nothing if active hurricane data is marked as failed.
    } elsif ($numfor =~ /FAILED/) {
        # Do nothing if forecasted hurricane data is marked as failed.
    } else {
        my $openfile = "Hurricane Arc File";  # Set the open file name for the header.

        # Open the hurricane arc file for writing, with error handling.
        open (HURRICANE_FH, ">$hurricane_arc_file") or die "Cannot open $hurricane_arc_file: $!";
        
        # Pass the filehandle (HURRICANE_FH) to Label::file_header for writing the header.
        Label::file_header($openfile, *HURRICANE_FH);
        
        # Write a comment in the file acknowledging Hans Ecke for storm track ideas.
        print HURRICANE_FH "#\n# Thanks to Hans Ecke <http://hans.ecke.ws/xplanet> for his idea of using GreatArcs to put in the storm tracks\n\n";
        
        # Process active hurricane data if storm tracking is enabled in settings.
        if ($stormsettings->{'StormTrackOnOff'} =~ /On/) {
            while ($counter < $numact) {
                # Check if the current storm is different from the next storm.
                if ($hurricanearcdataact[$counter]->{'num'} ne $hurricanearcdataact[($counter+1)]->{'num'}) {
                    $recounter++;  # Increment recounter when a new storm starts.
                    print HURRICANE_FH "\# $hurricanearcdataact[$counter]->{'name'}\n\n";
                }
                # If the current storm is the same as the next storm, write the storm track.
                elsif ($hurricanearcdataact[$counter]->{'num'} eq $hurricanearcdataact[($counter+1)]->{'num'}) {
                    # Ensure that the latitude/longitude difference isn't too large before printing the track.
                    if ( abs($hurricanearcdataact[$counter]->{'lat'} - $hurricanearcdataact[$counter+1]->{'lat'}) <= 10
                         && abs($hurricanearcdataact[$counter]->{'long'} - $hurricanearcdataact[$counter+1]->{'long'}) <= 10 ) {
                        printf HURRICANE_FH "%.1f %.1f %.1f %.1f color=$stormsettings->{'StormColorTrackReal'}\n", 
                               $hurricanearcdataact[$counter]->{'lat'}, $hurricanearcdataact[$counter]->{'long'}, 
                               $hurricanearcdataact[($counter+1)]->{'lat'}, $hurricanearcdataact[($counter+1)]->{'long'};
                    }
                } else {
                    # Add extra newlines to separate storm data entries.
                    print HURRICANE_FH "\n\n";
                }
                $counter++;  # Move to the next storm data entry.
            }

            # Reset the counters to process forecasted hurricane data.
            $counter = 0;
            $recounter = 0;

            while ($counter < $numfor) {
                # Check if the current storm is different from the previous storm.
                if ($hurricanearcdatafor[$counter]->{'num'} ne $hurricanearcdatafor[($counter-1)]->{'num'}) {
                    $recounter++;  # Increment recounter for new storms.
                }
                # If the current storm is the same as the next storm, write the forecasted storm track.
                if ($hurricanearcdatafor[$counter]->{'num'} eq $hurricanearcdatafor[($counter+1)]->{'num'}) {
                    printf HURRICANE_FH "%.1f %.1f %.1f %.1f color=$stormsettings->{'StormColorTrackPrediction'}\n", 
                           $hurricanearcdatafor[$counter]->{'lat'}, $hurricanearcdatafor[$counter]->{'long'}, 
                           $hurricanearcdatafor[($counter+1)]->{'lat'}, $hurricanearcdatafor[($counter+1)]->{'long'};
                } else {
                    # Add extra newlines to separate forecasted storm data entries.
                    print HURRICANE_FH "\n\n";
                }
                $counter++;  # Move to the next forecasted storm data entry.
            }
        }
    
        # Close the file after writing all data, with error handling.
        close HURRICANE_FH or warn "Could not close $hurricane_arc_file: $!";
    }
}


sub WriteoutHurricane {
    # 26 September 2024
    # Key Modifications:
        # The filehandle HURRICANE_FH is passed to Label::file_header
    # Error Handling for File Operations:
        # Added or die for the file opening operation to ensure the script stops if the file cannot be opened, and or warn for file closing to provide warnings 
        # in case closing fails
    # Consistent Filehandle Usage:
        # The filehandle HURRICANE_FH is used in all print and printf statements instead of the generic MF
    # Added inline comments to explain each part of the subroutine and the logic behind processing active and forecasted hurricane tracks
    my ($hurricane_counter) = @_;  # Argument for the number of hurricanes to process.
    my $recounter = 0;             # Initialize recounter for looping through hurricanes.
    my $lat;                       # Variable for latitude.
    my $long;                      # Variable for longitude.
    my @hurricanedata;             # Array to hold hurricane data (assumed populated elsewhere).
    my $type;                      # Variable for hurricane type.
    my $name;                      # Variable for hurricane name.
    my $speed;                     # Variable for hurricane speed.
    my $file;                      # Variable for file name.
    my $stormsettings;             # Settings for storm configuration (assumed populated elsewhere).
    
    # Check if the hurricane counter is valid and not set to "FAILED".
    if ($hurricane_counter !~ /FAILED/) {
        my $openfile = 'Hurricane';  # Set the open file name for the header.

        # Open the hurricane marker file for writing, with error handling.
        open (HURRICANE_FH, ">$hurricane_marker_file") or die "Cannot open $hurricane_marker_file: $!";
        
        # Pass the filehandle (HURRICANE_FH) to Label::file_header for writing the header.
        Label::file_header($openfile, *HURRICANE_FH);
        
        # Loop through each hurricane and write its data to the file.
        while ($recounter < $hurricane_counter) {
            # Extract hurricane data for the current recounter index.
            $type  = $hurricanedata[$recounter]->{'type'};
            $lat   = $hurricanedata[$recounter]->{'lat'};
            $lat   = sprintf("% 7.2f", $lat);  # Format latitude with two decimal places.
            $long  = $hurricanedata[$recounter]->{'long'};
            $long  = sprintf("% 7.2f", $long); # Format longitude with two decimal places.
            $name  = $hurricanedata[$recounter]->{'name'};
            $speed = $hurricanedata[$recounter]->{'speed'};
            $speed = sprintf("% 3.0f", $speed); # Format speed as an integer.
            $file  = $hurricanedata[$recounter]->{'file'};
            $file  = sprintf("%-17s", '"' . $file . '"'); # Format file name.

            # If storm names are turned on in the settings, write the name data to the file.
            if ($stormsettings->{'StormNameOnOff'} =~ /On/) {
                print HURRICANE_FH "$lat $long \"$name\" align=$stormsettings->{'StormAlignName'} color=$stormsettings->{'StormColorName'}";
                
                # If storm images are enabled in the settings, add the image data.
                if ($stormsettings->{'StormImageList'} =~ /\w/) {
                    print HURRICANE_FH " image=$stormsettings->{'StormImageList'}";
                    
                    # If transparency is enabled for the images, add the transparency data.
                    if ($stormsettings->{'StormImageTransparent'} =~ /\w/) {
                        print HURRICANE_FH " transparent=$stormsettings->{'StormImageTransparent'}";
                    }
                }
                print HURRICANE_FH "\n";  # Move to the next line after writing the storm name data.
            }

            # If storm details are turned on in the settings, write the detailed data to the file.
            if ($stormsettings->{'StormDetailList'} =~ /\w/) {
                my $tmp1 = $stormsettings->{'StormDetailList'};
                
                # Replace placeholders with actual hurricane data.
                $tmp1 =~ s/<lat>/$lat/g;
                $tmp1 =~ s/<long>/$long/g;
                $tmp1 =~ s/<type>/$type/g;
                $tmp1 =~ s/<name>/$name/g;
                $tmp1 =~ s/<speed>/$speed/g;
                
                # Write the detailed storm information.
                print HURRICANE_FH "$lat $long \"$tmp1\" align=$stormsettings->{'StormAlignDetail'} color=$stormsettings->{'StormColorDetail'}";
            }

            # If storm images are enabled in the settings, add the image data again.
            if ($stormsettings->{'StormImageList'} =~ /\w/) {
                print HURRICANE_FH " image=$stormsettings->{'StormImageList'}";
                if ($stormsettings->{'StormImageTransparent'} =~ /\w/) {
                    print HURRICANE_FH " transparent=$stormsettings->{'StormImageTransparent'}";
                }
            }

            # Move to the next line for the next hurricane entry.
            print HURRICANE_FH "\n";
            $recounter++;  # Increment the recounter to process the next hurricane.
        }

        # Close the file after writing all data, with error handling.
        close HURRICANE_FH or warn "Could not close $hurricane_marker_file: $!";
    }
}


1; # End of the module
