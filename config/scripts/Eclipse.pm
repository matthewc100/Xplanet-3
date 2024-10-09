package Eclipse;
use strict;
use warnings;
use Exporter 'import';
use Globals qw  (
    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_marker_file
    @eclipsedata
    @eclipsetrack
    @eclipserefined
    $settings
);

our @EXPORT_OK = qw(
    readineclipseindex
    readineclipsetrack
    datacurrent
    writeouteclipsemarker
    writeouteclipsearcboarder
    writeouteclipsearccenter
    writeouteclipsefilesnone
    writeouteclipselabel
    refinedata
);

## ECLIPSE SITES
my $eclipse_location = "https://sunearth.gsfc.nasa.gov/eclipse/SEpath/";
my $refined_eclipse_data = "https://www.wizabit.eclipse.co.uk/xplanet/files/local/update.data";

sub get_eclipsedata {
    # Key points of the subroutine:
        # Webpage fetching: The subroutine fetches an HTML page (SEpath.html) from a URL, processes the table rows containing eclipse data, and stores relevant data.
        # Data processing: For each valid row, the script cleans up the data and extracts eclipse information (e.g., date, type, Saros cycle, magnitude). Only future eclipses are processed.
        # Coordinates handling: Latitude and longitude are processed with rounding to format geographic coordinates.
        # Error handling: If a webpage fetch fails, the subroutine returns an error message (FAILED).
        # Progress updates: Prints a progress indicator (.) as data is processed and outputs status updates for each processed data set.
    my $counter = 0;                # Counter for the number of eclipse data entries.
    my $file  = "SEpath.html";      # The file to fetch from the web for eclipse data.
    my @eclipsedatatmp;             # Temporary array to store eclipse paths.
    my $eclipseoverride;            # A flag for handling failed data fetching.
    my $tsn;                        # Variable to store the timestamp of the data update.

    # Notify the user that the eclipse database is being built.
    print "Please Wait Building Eclipse Database. This could take a minute.\n.";
    
    # Get the webpage containing eclipse data.
    my $eclipsetxt  = get_webpage($eclipse_location . $file);
    
    # Check if the webpage fetch failed.
    if ($eclipsetxt =~ /FAILED/) {
        $eclipseoverride = 1;   # Set the override flag if the webpage fetch fails.
    } else {
        # Open the local eclipse data file to write new data, or terminate if the file can't be opened.
        open (MF, "<$eclipse_data_file") or die "Could not open $eclipse_data_file: $!";
        
        # Get the current local time and print the last update timestamp to the file.
        $tsn = localtime(time);
        print MF "#\n# Last Updated: $tsn\n#\n";
        print MF "[DATA]\n";     # Write a section header for the data.

        # Split the fetched HTML data into rows based on table row tags (<TR>).
        foreach (split(/<TR>/, $eclipsetxt)) {
            # Clean up the HTML by removing spaces and extraneous tags.
            s/^\s+//;
            s/\s+$//;
            s/\s+/ /g;
            s/<TD>/ /g;
            s/<\/A>//g;
            s/<A HREF="//g;
            s/">//g;
            s/path//g;
            s/map//g;
            
            # Split each row by spaces and assign data to variables.
            my ($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10) = split " ";
            
            # If the first field is a 4-digit year, it's a valid data row.
            if ($a1 =~ /\d\d\d\d/) {
                my $year = $a1;             # Year of the eclipse.
                my $monthtxt = $a2;         # Month (as text).
                my $monthnum = num_of_month($monthtxt);  # Convert the month to a numeric value.
                my $dayofmonth = $a3;       # Day of the month.
                my $type = $a4;             # Type of eclipse.
                $type = sprintf("%-7s", $type);  # Format the type with padding.
                my $saros = $a6;            # Saros cycle number.
                my $eclmag = $a7;           # Eclipse magnitude.
                my $duration = $a8;         # Duration of the eclipse.
                my $path = $a10;            # Path information.
                
                # Add the string "path" to the path for clarity.
                substr($path, 2, 0) = 'path';
                
                my $time_now = time;        # Get the current time.
                my $secsperday = 86400;     # Seconds in a day.
                
                # Convert the eclipse date to a Unix timestamp.
                my $time_state = timelocal(59,59,23, $dayofmonth, $monthnum, $year);
                
                # Only process future eclipses (ignore past eclipses).
                if ($time_state < $time_now) {
                    # Do nothing for past eclipses.
                } else {
                    # Print a progress indicator and write the eclipse data to the file.
                    print ".";
                    print MF "$dayofmonth, $monthtxt, $year, $type, $saros, $eclmag, $duration, CRUDE\n";
                    
                    # Store the eclipse path in the temporary array for further data fetching.
                    push @eclipsedatatmp, { 'path' => $path };
                    $counter++;  # Increment the counter for each valid eclipse entry.
                }
            }
        }
    }

    my $recounter = 0;   # Counter for processing individual eclipse paths.
    
    print "\nBuilt Index $counter Entries, Starting to fill data sets.\n";

    # Loop through each path collected during the first data fetch.
    while ($recounter < $counter) {
        # Fetch the individual eclipse data page for each path.
        $eclipsetxt = get_webpage($eclipse_location . $eclipsedatatmp[$recounter]->{'path'});
        
        # If the fetch fails, return the failure message.
        if ($eclipsetxt =~ /FAILED/) {
            return $eclipsetxt;
        } else {
            # Print a section header for track data in the file.
            print MF "[TRACK,$recounter]\n";
            
            # Split the track data using a specific time format pattern.
            foreach (split(/\d\dm\d\d.\ds/, $eclipsetxt)) {
                # Clean up spaces in the data.
                s/^\s+//;
                s/\s+$//;
                s/\s+/ /g;
                
                # Split the cleaned data into individual values.
                my ($a1, $a2, $a3, $a4, $a5, $a6, $a7, $a8, $a9, $a10, $a11, $a12, $a13, $a14) = split " ";
                
                # Process valid lines that contain a time in the format "HH:MM".
                if ($a1 =~ /\d\d:\d\d/) {
                    my ($hour, $min) = split ":", $a1;  # Split the time into hour and minute.
                    
                    # Processing coordinates (north latitude/longitude, south latitude/longitude, central coordinates).
                    my $northlat = format_coordinates($a2, $a3);
                    my $northlong = format_coordinates($a4, $a5);
                    my $southlat = format_coordinates($a6, $a7);
                    my $southlong = format_coordinates($a8, $a9);
                    my $centrallat = format_coordinates($a10, $a11);
                    my $centrallong = format_coordinates($a12, $a13);
                    
                    # Print a progress indicator and write the formatted data to the file.
                    print ".";
                    printf MF "%03d,%02d:%02d, $northlat, $northlong, $centrallat, $centrallong, $southlat, $southlong,\n", $recounter, $hour, $min;
                }
            }
        }

        # Print a message indicating the data set has been processed.
        print "\nFilled Data Set #$recounter\n";
        
        # Move to the next path.
        $recounter++;
    }
    
    # Close the file once all data has been processed.
    close MF;
}

# Helper subroutine to process coordinates (for latitude and longitude).
sub format_coordinates {
    my ($value, $remainder) = @_;
    my ($tmp, $tmp1) = split '\.', $remainder;
    my $tmp2 = substr($tmp1, -1, 1);  # Extract the last digit.
    chop $tmp1;  # Remove the last character from tmp1.
    
    # Round up the value if needed.
    if ($tmp1 >= 5) { $tmp++; }
    
    return $value . '.' . $tmp . $tmp2;  # Return the formatted coordinate.
}


sub readineclipseindex {
    # File opening: It opens a file, and if it fails, it terminates with an error.
    # Data processing: It reads the file line by line, splitting each line into individual fields using commas as separators.
    # Data type detection: It checks if the first field on the line marks the line as DATA, TRACK, or a COMMENT. Only lines marked as DATA are processed and stored.
    # Storing parsed data: For lines identified as DATA, it extracts and stores information (e.g., date, eclipse type, etc.) into a hash, which is then pushed into an array.
    # Counter: It keeps a count of the number of DATA entries processed and returns that count at the end.

    # Open the file for reading. The file path is stored in $eclipse_data_file.
    # If the file cannot be opened, the script will terminate with an error message.
    open (MF, "<$eclipse_data_file") or die "Could not open $eclipse_data_file: $!";

    # Initialize variables.
    my $datatype;         # Will store the type of line being processed (DATA, TRACK, or COMMENT).
    my $counter = 0;      # A counter to track the number of DATA entries processed.
    my @eclipsedata;      # An array to store the parsed data as hashes.

    # Read the file line by line.
    while (<MF>) {

        # Split each line on newline characters.
        foreach (split "\n" ) {

            # Split each line by commas to get individual data fields.
            my ($data1, $data2, $data3, $data4, $data5, $data6, $data7, $data8) = split ",";

            # Determine the type of data based on the first field.
            if ($data1 =~ /DATA/) {
                $datatype = 'DATA';       # Line contains data.
            }
            elsif ($data1 =~ /TRACK/) {
                $datatype = 'TRACK';      # Line contains track information.
            }
            elsif ($data1 =~ /#/) {
                $datatype = 'COMMENT';    # Line is a comment (starts with #).
            }
            else {
                # If the first field doesn't match any known type, do nothing.
            }

            # If the line is a comment, skip further processing for this iteration.
            if ($datatype eq 'COMMENT') {
                next;
            }

            # Process data lines.
            if ($datatype eq 'DATA') {
                # Ignore the header line that contains the word "DATA".
                if ($data1 =~ /DATA/) {
                    next;
                } else {
                    # For a valid data line, store the fields in a hash and push it to the array.
                    push @eclipsedata, {
                        'dayofmonth'     => $data1,  # Day of the month.
                        'monthtxt'       => $data2,  # Month (text form).
                        'year'           => $data3,  # Year of the eclipse.
                        'type'           => $data4,  # Type of eclipse.
                        'saros'          => $data5,  # Saros cycle number.
                        'eclmag'         => $data6,  # Eclipse magnitude.
                        'duration'       => $data7,  # Duration of the eclipse.
                        'detail'         => $data8,  # Any additional details.
                    };

                    # Increase the counter for each processed data entry.
                    $counter++;
                }
            }
        }
    }

    # Close the file after reading.
    close MF;

    # Return the number of processed data entries.
    return $counter;
}


sub readineclipsetrack {
    my($dataset) = @_;
    open (MF, "<$eclipse_data_file");
    my $datatype;
    my $counter = 0;
    my @eclipsetrack;
    
    while (<MF>) {
        foreach (split "\n" ) {
            my ($data1, $data2, $data3, $data4, $data5, $data6, $data7, $data8) = split ",";
            if ($data1 =~ /DATA/) {
                $datatype = 'DATA';
            }
            elsif ($data1 =~ /TRACK/) {
                $datatype = 'TRACK';
            }
            elsif ($data1 =~ /#/) {
                $datatype = 'COMMENT';
            }
            
            if ($datatype eq 'COMMENT') {};
            if ($datatype eq 'DATA') {}
            if ($datatype eq 'TRACK') {
                $dataset = sprintf("%03d",$dataset);
                #print "$data1, $dataset\n";
                if ($data1 eq $dataset) {
                    if ($data1 =~ /TRACK/) {}
                    else {
                        my ($hour, $min) = split ":",$data2;
                        
                        push @eclipsetrack, {
                            'hour'           => $hour,
                            'minute'         => $min,
                            'nlat'           => $data3,
                            'nlong'          => $data4,
                            'slat'           => $data7,
                            'slong'          => $data8,
                            'clat'           => $data5,
                            'clong'          => $data6,
                        };
                        #print "$counter: $hour:$min, $data3, $data4, $data5, $data6, $data7, $data8\n";
                        
                        $counter++;
                    }
                }
            }
        }
    }
    
    close MF;
    return $counter;
}

sub datacurrent {
    # Key points of the subroutine:
        # Arguments and setup:
            # The subroutine takes one argument, $counter, which represents the number of eclipse data entries to process.
            # The $notice variable is calculated from a settings hash ($settings->{'EclipseNotifyTimeHours'}) and converted from hours to seconds (multiplying by 3600).
        # Main loop:
            # The subroutine loops through each eclipse entry in @eclipsedata using a $recounter until it reaches $counter.
            # Each eclipse entry's date is converted to a Unix timestamp using timelocal(), which creates a timestamp for 11:59:59 PM on the given day, month, and year.
        # Time comparison:
            # The current time is retrieved using the time() function.
            # If the current time is before the next eclipse, the subroutine calculates the time difference between now and the eclipse.
            # If the time difference is smaller than the notification period ($notice), the index ($recounter) of that eclipse is returned, signaling that the 
            #   eclipse is close enough to trigger a notification.
            # If the eclipse is farther away than the notification period, the subroutine returns 'NONE' (currently intended to be modified for testing purposes).
        # Return:
            # The function returns either the index of the upcoming eclipse ($recounter) if it's close enough for notification, or 'NONE' if the eclipse is too far in the future.
    
    # Accepts one argument: the number of eclipse data entries to process (stored in $counter).
    my ($counter) = @_;

    # 'Notice' is the number of seconds before the next eclipse for which a notification should be triggered.
    # It is calculated from the 'EclipseNotifyTimeHours' setting in $settings.
    my $notice = $settings->{'EclipseNotifyTimeHours'} * 3600;

    # Initialize variables.
    my $recounter = 0;     # A counter to iterate over the eclipse data entries.
    my $monthnum;          # Will hold the numeric value of the month.
    my $next_eclipse;      # Will store the Unix timestamp for the next eclipse.
    my $time_now;          # Stores the current time as a Unix timestamp.
    my @eclipsedata;       # Array to hold eclipse data (assumed to be initialized elsewhere).
    my $result;            # Stores the result (time difference between now and the next eclipse).

    # Loop through the eclipse data until the recounter reaches the number of entries.
    while ($recounter < $counter) {

        # Convert the month text into its corresponding numeric value (January = 0, December = 11).
        $monthnum = num_of_month($eclipsedata[$recounter]->{'monthtxt'});

        # Convert the eclipse date to a Unix timestamp using the timelocal function.
        # Assumes the eclipse occurs at 11:59:59 PM (23:59:59) on the given day, month, and year.
        $next_eclipse = timelocal(59,59,23,$eclipsedata[$recounter]->{'dayofmonth'}, $monthnum, $eclipsedata[$recounter]->{'year'});

        # Get the current time as a Unix timestamp.
        $time_now = time;

        # If the current time is earlier than the next eclipse time (i.e., the eclipse is in the future):
        if ($time_now < $next_eclipse) {

            # Calculate the time difference between now and the next eclipse.
            $result = $next_eclipse - $time_now;

            # If the time difference is less than the notification period (i.e., close to the eclipse):
            if (($next_eclipse - $time_now) < $notice) {

                # Return the index of the next eclipse (recounter).
                return $recounter;
            } else {
                # If the eclipse is farther away than the notification period, return 'NONE'.
                # Note: This could be modified after testing, as indicated in the comment.
                return 'NONE';
            }
        }

        # Increment the recounter to move to the next eclipse entry.
        $recounter++;
    }
}


sub writeouteclipsemarker {
    # 26 September 2024
    # Key Modifications:
        # Pass Filehandle to Label::file_header:  
            # We now pass the filehandle MARKER_FH to Label::file_header by modifying the call:
        # Error Handling for File Operations:
            # Added error handling (or die) when opening the file and a warning (or warn) when closing the file to make it more robust.
        # Consistent Filehandle Usage:
            # The filehandle MARKER_FH is used consistently in all print and printf statements instead of MF, ensuring that the right filehandle is referenced.

    my ($counter) = @_;     # $counter holds the number of eclipse data points.
    my $recounter = 1;      # Initialize recounter to start processing eclipse data from the second entry.
    my @eclipsetrack;       # Array to hold eclipse tracking data (assumed populated elsewhere).
    
    # Check if $counter indicates a failed condition (e.g., "FAILED").
    if ($counter =~ /FAILED/) {
        # Do nothing if $counter is "FAILED".
    } else {
        # Define the name of the open file (for header purposes).
        my $openfile = 'Eclipse';
        
        # Open the eclipse marker file for writing.
        # Add error handling in case the file cannot be opened.
        open (MARKER_FH, ">$eclipse_marker_file") or die "Could not open $eclipse_marker_file: $!";
        
        # Pass the filehandle (MARKER_FH) to Label::file_header for writing the file header.
        Label::file_header($openfile, *MARKER_FH);
        
        # Write the first and last eclipse data points to the file.
        # These are formatted with the latitude, longitude, time, and display properties.
        printf MARKER_FH "$eclipsetrack[1]->{'clat'}$eclipsetrack[1]->{'clong'} \"%02d:%02d\" color=Grey align=left\n",
            $eclipsetrack[1]->{'hour'}, $eclipsetrack[1]->{'minute'};
        
        printf MARKER_FH "$eclipsetrack[($counter-1)]->{'clat'}$eclipsetrack[($counter-1)]->{'clong'} \"%02d:%02d\" color=Grey align=right\n",
            $eclipsetrack[($counter-1)]->{'hour'}, $eclipsetrack[($counter-1)]->{'minute'};
        
        # Loop through the rest of the eclipse data.
        while ($recounter < $counter) {
            # If the minute matches specific values (e.g., 00, 20, 40), write the data to the file.
            if ($eclipsetrack[$recounter]->{'minute'} =~ /[240]0/) {
                printf MARKER_FH "$eclipsetrack[$recounter]->{'clat'}$eclipsetrack[$recounter]->{'clong'} \"%02d:%02d\" color=Grey align=top symbolsize=4\n",
                    $eclipsetrack[$recounter]->{'hour'}, $eclipsetrack[$recounter]->{'minute'};
                $recounter++;
            }
            
            # Increment the recounter to process the next data point.
            $recounter++;
        }
    }
    
    # Close the file after all data has been written.
    close MARKER_FH or warn "Could not close $eclipse_marker_file: $!";
}


sub writeouteclipsearcboarder {
    my ($counter) = @_;
    my $recounter = 1;
    my @eclipsetrack;
    
    if ($counter =~ /FAILED/) {}
    else {
        my $openfile = 'Eclipse';
        open (MF, ">>$eclipse_arc_file");
        print MF "\n\n# Northern Limit Track\n";
        
        while  ($recounter < $counter) {
            if (($recounter+1) != $counter) {
                print MF "$eclipsetrack[$recounter]->{'nlat'}$eclipsetrack[$recounter]->{'nlong'}$eclipsetrack[$recounter+1]->{'nlat'}$eclipsetrack[$recounter+1]->{'nlong'} color=Grey spacing=0.2\n";
            }
            $recounter++
        }
        
        $recounter  = 1;
        print MF "\n\n# Southern Limit Track\n";
        while  ($recounter < $counter) {
            if (($recounter+1) != $counter) {
                print MF "$eclipsetrack[$recounter]->{'slat'}$eclipsetrack[$recounter]->{'slong'}$eclipsetrack[$recounter+1]->{'slat'}$eclipsetrack[$recounter+1]->{'slong'} color=Grey spacing=0.2\n";
            }
            $recounter++
        }
        close MF;
    }
}

sub writeouteclipsearccenter {
    # 26 September 2024
    # Key Modifications:
        # Pass Filehandle to Label::file_header:  
            # We now pass the filehandle MARKER_FH to Label::file_header by modifying the call:
        # Error Handling for File Operations:
            # Added error handling (or die) when opening the file and a warning (or warn) when closing the file to make it more robust.
        # Consistent Filehandle Usage:
            # The filehandle MARKER_FH is used consistently in all print and printf statements instead of MF, ensuring that the right filehandle is referenced.

 
    my ($counter) = @_;     # $counter holds the number of eclipse data points.
    my $recounter = 1;      # Initialize recounter to start processing eclipse data from the second entry.
    my @eclipsetrack;       # Array to hold eclipse tracking data (assumed populated elsewhere).
    
    # Check if $counter indicates a failed condition (e.g., "FAILED").
    if ($counter =~ /FAILED/) {
        # Do nothing if $counter is "FAILED".
    } else {
        # Define the name of the open file (for header purposes).
        my $openfile = 'Eclipse';
        
        # Open the eclipse arc file for writing.
        # Add error handling in case the file cannot be opened.
        open (ARC_FH, ">$eclipse_arc_file") or die "Could not open $eclipse_arc_file: $!";
        
        # Pass the filehandle (ARC_FH) to Label::file_header for writing the file header.
        Label::file_header($openfile, *ARC_FH);
        
        # Write a comment line indicating the start of the central track data.
        print ARC_FH "# Central Track\n";
        
        # Loop through the eclipse tracking data and print each relevant data point.
        while  ($recounter < $counter) {
            # If this is not the last recounter, print the current and next data point.
            if (($recounter + 1) != $counter) {
                print ARC_FH "$eclipsetrack[$recounter]->{'clat'}$eclipsetrack[$recounter]->{'clong'}$eclipsetrack[$recounter+1]->{'clat'}$eclipsetrack[$recounter+1]->{'clong'} color=Black spacing=0.2\n";
            }
            # Increment the recounter to move to the next data point.
            $recounter++;
        }
        
        # Close the file after all data has been written, with error handling.
        close ARC_FH or warn "Could not close $eclipse_arc_file: $!";
    }
}


sub writeouteclipsefilesnone {
    # Key actions:
        # Opening Files:
            # The subroutine opens two files, $eclipse_marker_file and $eclipse_arc_file, for writing. These files are overwritten if they exist (> mode).
        # Writing Headers:
            # After opening each file, it passes the variable $openfile to Label::file_header($openfile), which presumably writes some metadata or 
            # header information into the file.
        # Closing Files:
            # After writing the header, the subroutine closes the files. If closing fails, a warning message is displayed (using warn).
    
    # Open the eclipse marker file for writing, with error handling.
    open (MARKER_FH, ">$eclipse_marker_file") or die "Could not open $eclipse_marker_file: $!";
    
    # Assign a name to the open file (used for the header).
    my $openfile = 'Eclipse';
    
    # Call Label::file_header and pass the filehandle MARKER_FH.
    Label::file_header($openfile, *MARKER_FH);

    # Close the marker file with error handling.
    close MARKER_FH or warn "Could not close $eclipse_marker_file: $!";
    
    # Open the eclipse archive file for writing, with error handling.
    open (ARC_FH, ">$eclipse_arc_file") or die "Could not open $eclipse_arc_file: $!";
    
    # Call Label::file_header and pass the filehandle ARC_FH.
    Label::file_header($openfile, *ARC_FH);
    
    # Close the archive file with error handling.
    close ARC_FH or warn "Could not close $eclipse_arc_file: $!";
}


sub writeouteclipselabel {
    my ($record_number,$track_number,$countdown) = @_;
    $countdown *= 1;
    my $answer;
    my @eclipsetrack;
    my @eclipsedata;
    my $minutes;
    $answer = ($countdown / 3600 );
    my ($hours,$ignore) = split('\.',$answer);
    $countdown = ($countdown-($hours*3600));
    $answer = ($countdown / 60 );
    ($minutes,$ignore) = split('\.',$answer);

    my $biggestlat = $eclipsetrack[1]->{'clat'};
    my $smallestlat = $eclipsetrack[1]->{'clat'};
    my $biggestlong = $eclipsetrack[1]->{'clong'};
    my $smallestlong = $eclipsetrack[1]->{'clong'};
    my $counter = 2;
    
    while ($counter < ($track_number+1)) {
        if ($biggestlat < $eclipsetrack[$counter]->{'clat'}) {
            $biggestlat = $eclipsetrack[$counter]->{'clat'};
        }
        if ($smallestlat > $eclipsetrack[$counter]->{'clat'}) {
            $smallestlat = $eclipsetrack[$counter]->{'clat'};
        }
        if ($biggestlong < $eclipsetrack[$counter]->{'clong'}) {
            $biggestlong = $eclipsetrack[$counter]->{'clong'};
        }
        if ($smallestlong > $eclipsetrack[$counter]->{'clong'}) {
            $smallestlong = $eclipsetrack[$counter]->{'clong'};
        }
        $counter++;
    }
    
    my $lat = ($biggestlat + $smallestlat) / 2;
    my $long = ($biggestlong + $smallestlong) / 2;
    
    open(MF, ">>$eclipse_marker_file");
    printf MF "\n\n-55 1 \"A$eclipsedata[$record_number]->{'type'} Eclipse will be occuring in $hours hours and $minutes minutes, starting at $eclipsedata[$record_number]->{'dayofmonth'} $eclipsedata[$record_number]->{'monthtxt'} $eclipsedata[$record_number]->{'year'} %02d:%02d GMT\" color=White image=none position=pixel\n",$eclipsetrack[1]->{'hour'},$eclipsetrack[1]->{'minute'};
    print MF "-45 1 \"To view this the best loaction is Latitude $lat ,Longitude $long,\" color=White image=none position=pixel\n";
    print MF "-35 1 \"The Eclipse Track has been put on the map, and will remain until the eclipse has passed.\" color=White image=none position=pixel\n";
    close MF;
}

sub refinedata {
    my ($record_number) = @_;
    my $counter = 0;
    my $recounter = 0;
    my $linecounter = 0;
    my $datac = 0;
    my $flag = 0;
    my $updatefile = "http://www.wizabit.eclipse.co.uk/xplanet/files/local/update.data";
    my $updateddata = get_webpage($updatefile);
    my $updatedata;
    my @eclipserefined;
    my @eclipsetempfile =();
    my @eclipsedata;

    
    if ($updatedata =~ /FAILED/) {}
    else {
        foreach (split "\n",$updateddata) {
            my ($t1,$t2,$nlat,$nlong,$clat,$clong,$slat,$slong) = split ",";
            
            if ($t1 =~ /(\d\d)(\w\w\w)(\d\d\d\d)/) {
                my ($day,$month,$year) = ($1,$2,$3);
                my ($hour,$minute) = split ":",$t2;
                
                $clong = sprintf("% 6.2f",$clong);
                $clat = sprintf("% 6.2f",$clat);
                $slong = sprintf("% 6.2f",$slong);
                $slat = sprintf("% 6.2f",$slat);
                $nlong = sprintf("% 6.2f",$nlong);
                $nlat = sprintf("% 6.2f",$nlat);
                
                push @eclipserefined, {
                    'day'       => $day,
                    'month'     => $month,
                    'year'      => $year,
                    'hour'      => $hour,
                    'minute'    => $minute,
                    'nlat'      => $nlat,
                    'nlong'     => $nlong,
                    'clat'      => $clat,
                    'clong'     => $clong,
                    'slat'      => $slat,
                    'slong'     => $slong,
                };
                $counter++;
            }
        }
        
        open (MF, "<$eclipse_data_file");
        while (<MF>) {
            foreach (split "\n",) {
                my ($data1,$data2,$data3,$data4,$data5,$data6,$data7,$data8) = split ",";
                @eclipsetempfile = ();
                
                push @eclipsetempfile, {
                    'element1'        => $data1,
                    'element2'        => $data2,
                    'element3'        => $data3,
                    'element4'        => $data4,
                    'element5'        => $data5,
                    'element6'        => $data6,
                    'element7'        => $data7,
                    'element8'        => $data8,
                };
                $recounter++;
            }
        }
        close MF;
        
        substr($eclipsedata[$record_number]->{'monthtxt'},0,1) = "";
        substr($eclipsedata[$record_number]->{'year'},0,1) = "";
        #print "$eclipserefined[0]->{'day'}:$eclipsedata[$record_number]->{'dayofmonth'} and $eclipserefined[0]->{'month'}:$eclipsedata[$record_number]->{'monthtxt'} and $eclipserefined[0]->{'year'}:$eclipsedata[$record_number]->{'year'}";
        
        if ($eclipserefined[0] -> {'day'} eq $eclipsedata[$record_number] -> {'dayofmonth'} && $eclipserefined[0] -> {'month'} eq $eclipsedata[$record_number] -> {'monthtxt'} && $eclipserefined[0] -> {'year'} eq $eclipsedata[$record_number] -> {'year'}) {
            open (MF, ">$eclipse_data_file");
            my $tsn = localtime(time);
            print MF "\#\n\# Last Updated: $tsn\n\#\n";
            $eclipsedata[$record_number]->{'detail'} = 'INT';
            
            while ($linecounter < $recounter) {
                if ($eclipsetempfile[$linecounter]->{'element1'} =~ /\#/) {
                    $flag = 2;
                }
                
                if ($eclipsetempfile[$linecounter]->{'element1'} =~ /\[DATA/) {
                    $flag = 3;
                }
                
                if ($eclipsetempfile[$linecounter]->{'element1'} =~ /\[TRACK/) {
                    my ($tmp1,$tmp2) = split "]",$eclipsetempfile[$linecounter]->{'element2'};
                    chop $tmp2;
                    chop $tmp2;
                    
                    if ($tmp1 eq $record_number) {
                        $flag = 1;
                    }
                    else {
                        $flag = 5;
                    }
                }
                
                if ($flag eq 0) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'},$eclipsetempfile[$linecounter]->{'element3'},$eclipsetempfile[$linecounter]->{'element4'},$eclipsetempfile[$linecounter]->{'element5'},$eclipsetempfile[$linecounter]->{'element6'},$eclipsetempfile[$linecounter]->{'element7'},$eclipsetempfile[$linecounter]->{'element8'}\n";
                }
                elsif ($flag eq 1) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'}\n";
                    
                    while ($datac < $counter) {
                        printf MF "%03d,$eclipserefined[$datac]->{'hour'}:$eclipserefined[$datac]->{'minute'}, $eclipserefined[$datac]->{'nlat'}, $eclipserefined[$datac]->{'nlong'}, $eclipserefined[$datac]->{'clat'}, $eclipserefined[$datac]->{'clong'}, $eclipserefined[$datac]->{'slat'}, $eclipserefined[$datac]->{'slong'}\n",$record_number;
                        $datac++;
                    }
                    $flag = 2;
                }
                elsif ($flag eq 2) {}
                elsif ($flag eq 4) {
                    substr($eclipsetempfile[$linecounter]->{'element2'},0,1) = "";
                    substr($eclipsetempfile[$linecounter]->{'element3'},0,1) = "";
                    if ($eclipserefined[0]->{'day'} eq $eclipsetempfile[$linecounter]->{'element1'} && $eclipserefined[0]->{'month'} eq $eclipsetempfile[$linecounter]->{'element2'} && $eclipserefined[0]->{'year'} eq $eclipsetempfile[$linecounter]->{'element3'}) {
                        print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'},$eclipsetempfile[$linecounter]->{'element3'},$eclipsetempfile[$linecounter]->{'element4'},$eclipsetempfile[$linecounter]->{'element5'},$eclipsetempfile[$linecounter]->{'element6'},$eclipsetempfile[$linecounter]->{'element7'}, INTER\n";
                    }
                    else {
                        print MF "$eclipsetempfile[$linecounter]->{'element1'},$eclipsetempfile[$linecounter]->{'element2'},$eclipsetempfile[$linecounter]->{'element3'},$eclipsetempfile[$linecounter]->{'element4'},$eclipsetempfile[$linecounter]->{'element5'},$eclipsetempfile[$linecounter]->{'element6'},$eclipsetempfile[$linecounter]->{'element7'},$eclipsetempfile[$linecounter]->{'element8'}\n";
                    }
                }
                elsif ($flag eq 3) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'}\n";
                    $flag = 4;
                }
                elsif ($flag eq 5) {
                    print MF "$eclipsetempfile[$linecounter]->{'element1'}$eclipsetempfile[$linecounter]->{'element2'}\n";
                    $flag = 0;
                }
                
                $linecounter++;
            }
        }
        close MF;
    }
}

1; # End of the module with a true value