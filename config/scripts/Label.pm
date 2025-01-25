package Label;
use strict;
use warnings;
use Data::Dumper;
use Time::Local;  # Load the Time::Local module


# Reference the global $DEBUG variable from the main script
use vars qw($DEBUG);

use Globals qw($label_file $labelsettings);  # Import $labelsettings from Globals

    # 26 September 2024
    # Key Changes
        # Pass Filehandle to file_header:
            # The filehandle MF is passed to file_header explicitly
        # Error Handling for File Operations:
            # Added or die for the file opening operation to ensure the script stops if the file cannot be opened.
        # Declare %warning_length: 
            # The %warning_length hash is declared and initialized with default values using 
            # the // operator, which ensures that the values default to 1 if they are undefined. This avoids the errors about %warning_length not being declared.
        # Comments:
            # Added detailed inline comments explaining each part of the subroutine for easier maintenance and understanding.

    # Accepts multiple update flags as arguments.
    # Globals::get_ini_settings();  # Ensure settings are loaded

    # Before accessing $labelsettings, add a check and print statements to confirm it is defined and populated:
 
sub WriteoutLabel {
    # Invocation parameters control which types to process
    my ($update_earth, $update_norad, $update_cloud, $update_storm, $update_volcano, $update_label) = @_;

    # Declare and initialize the types and their invocation flags
    my %types_to_check = (
        "Earthquake" => $update_earth,
        "NORAD"      => $update_norad,
        "Cloud"      => $update_cloud,
        "Storm"      => $update_storm,
        "Volcano"    => $update_volcano,
    );

    # Declare and initialize positions for each type
    my %type_positions = (
        "Earthquake" => [-68, -13],
        "NORAD"      => [-83, -13],
        "Cloud"      => [-98, -13],
        "Storm"      => [-113, -13],
        "Volcano"    => [-128, -13],
    );

    # Declare and initialize colors for status levels
    my %type_colors = (
        "OK"    => $Globals::modules{'labelupdate'}{'Label.Color.Ok'}    // 'Green',
        "Warn"  => $Globals::modules{'labelupdate'}{'Label.Color.Warn'}  // 'Yellow',
        "Error" => $Globals::modules{'labelupdate'}{'Label.Color.Error'} // 'Red',
    );


    # Declare and initialize the found data tracker
    my %found_data = map { $_ => 0 } keys %types_to_check;

    # Get current timestamp for "not found" messages
    my $formatted_time = get_current_time();

    # Step 1: Read existing entries into a hash, keyed by type
    my %current_entries;  # Declare to store lines from updatelabel
    if (-e $label_file) {
        open(my $read_fh, '<', $label_file) or die "Cannot open $label_file for reading: $!";
        while (<$read_fh>) {
            chomp;
            my $line = $_;
            foreach my $type (keys %types_to_check) {
                if ($line =~ /\b$type\b/i) {
                    $current_entries{$type} = $line;  # Store existing line for the type
                    last;
                }
            }
        }
        close($read_fh);
    }

    # Step 2: Ensure every type has a corresponding entry
    foreach my $type (keys %types_to_check) {
        if ($types_to_check{$type} && exists $current_entries{$type}) {
            # Update existing data
            $current_entries{$type} = process_data_for_type($type, \%type_positions, \%type_colors);
            $found_data{$type} = 1;
        } elsif ($types_to_check{$type}) {
            # Add "not found" entry for missing types flagged for processing
            my ($Yco, $Xco) = @{$type_positions{$type}};
            $current_entries{$type} = generate_not_found_message($type, \%type_positions, \%type_colors, $formatted_time);
        } elsif (!exists $current_entries{$type}) {
            # Ensure "not found" entry for types not updated and not present in the file
            my ($Yco, $Xco) = @{$type_positions{$type}};
            $current_entries{$type} = generate_not_found_message($type, \%type_positions, \%type_colors, $formatted_time);
        }
    }

    # Step 3: Write the header and sorted data to the marker file
    open(my $write_fh, '>', $label_file) or die "Cannot open $label_file for writing: $!";
    file_header('UpdateLabel', $write_fh);

    # Collect all lines into an array for sorting
    my @lines;
    foreach my $type (keys %current_entries) {
        my $line = $current_entries{$type};
        my ($x_pos) = ($line =~ /^(-?\d+\.?\d*)\s/);
        $x_pos //= 0;  # Default to 0 if x_pos extraction fails
        push @lines, { x_pos => $x_pos, line => $line };
    }

    # Sort lines by x-position in descending order
    @lines = sort { $b->{x_pos} <=> $a->{x_pos} } @lines;

    # Write sorted lines to the file
    foreach my $entry (@lines) {
        print $write_fh $entry->{line} . "\n";
    }

    close($write_fh);
}


# Subroutine to process data for a specific type and return formatted string
sub process_data_for_type {
    my ($type, $type_positions, $type_colors) = @_;                              # Receive %type_positions as a reference

    # Example position and color assignments, replace with actual data processing as needed
    my ($Yco, $Xco) = @{$type_positions->{$type}};
    my $color = $type_colors->{'OK'};                              # Assume the color is determined dynamically
    my $formatted_time = get_current_time();
    return "$Yco $Xco \"$type information last updated $formatted_time\" color=$color image=none position=pixel";
}

# Subroutine to output a "not found" message at specified coordinates for missing data
sub generate_not_found_message {
    my ($type, $type_positions, $type_colors, $formatted_time) = @_;
    my ($Yco, $Xco) = @{$type_positions->{$type}};
    my $color = $type_colors->{'Error'};                        # Use the "Error" color for "not found" messages

    return "$Yco $Xco \"$type information not found $formatted_time\" color=$color image=none position=pixel";
}

# Helper to get the current timestamp for output messages
sub get_current_time {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    $mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon];
    return sprintf("%02d-%s-%04d %02d:%02d", $mday, $mon, $year, $hour, $min);
}

sub process_update {
    my ($fh, $update_status, $type, $ok_color, $warn_color, $failed_color, 
        $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
        $monthlet, $yeartime, $colour, $image, $position, $warning_length, $wday) = @_;

    # Remove the last character from the timestamp to clean up formatting
    substr($yeartime, -1, 1, "");  

    # Case 1: Update failed, and the current color is OK
    if ($update_status eq 'FAILED' && $colour =~ /$ok_color/) {
        # Downgrade to a warning status
        print $fh " $weekday $monthday $monthlet $yeartime\" color=$warn_color";

    # Case 2: Update failed, and the current color is Warning
    } elsif ($update_status eq 'FAILED' && $colour =~ /$warn_color/) {
        
        # Convert timestamp to epoch time for comparison
        my $mon = num_of_month($monthlet);                      # Convert month name to numeric
        chomp $yeartime;
        my ($year_part, $min, $sec) = split(":", $yeartime, 3);
        my ($year, $hour) = split(",", $year_part, 2);

        $year -= 1900;                                          # Convert to Perl's epoch format

        my $time_state = timelocal($sec, $min, $hour, $monthday, $mon, $year);
        my $time_difference = time() - $time_state;             # Time elapsed since last update

        # Determine whether to keep as warning or downgrade to failed
        if ($time_difference < $warning_length->[0]->{$type}) {
            print $fh " $weekday $monthday $monthlet $yeartime\" color=$warn_color";
        } else {
            print $fh " $weekday $monthday $monthlet $yeartime\" color=$failed_color";
        }

    # Case 3: Update failed, and the status is already Failed
    } elsif ($update_status eq 'FAILED') {
        
        # Keep as failed
        print $fh " $weekday $monthday $monthlet $yeartime\" color=$failed_color";

    # Case 4: Update succeeded
    } else {
        
        # Generate a new timestamp for the update
        my ($sec, $min, $hour, $mday, $mon, $current_year) = localtime();

        $current_year += 1900;                                   # Adjust year to full format

        my $thisday = (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday];  # Day of the week
        my $thismonth = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];  # Month name
        printf $fh " $thisday $mday $thismonth $current_year,%02d:%02d:%02d\" color=$ok_color", $hour, $min, $sec;
    }

    # Write image and position data for the label
    print $fh " image=none position=pixel\n";
}


sub process_last_update {
    my ($fh, $warning_length, $ok_color, $warn_color, $failed_color, 
        $time_now, $Yco, $Xco, $text1, $text2, $text3, $text4, 
        $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position) = @_;

    # Convert the timestamp to epoch time
    my $mon = num_of_month($monthlet);
    chomp $yeartime;
    my ($year_part, $min, $sec) = split(":", $yeartime, 3);
    my ($year, $hour) = split(",", $year_part, 2);

    $year -= 1900;  # Adjust year for Perl's epoch format

    my $time_state = timelocal($sec, $min, $hour, $monthday, $mon, $year);
    my $time_difference = $time_now - $time_state;  # Time difference in seconds

    # Call update_time_status based on the type in $text1
    if ($text1 =~ /Earthquake/) {
        update_time_status($fh, 'quake', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Cloud/) {
        update_time_status($fh, 'cloud', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /NORAD/) {
        update_time_status($fh, 'norad', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Storm/) {
        update_time_status($fh, 'hurricane', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Volcano/) {
        update_time_status($fh, 'volcano', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position);
    }
}


sub update_time_status {
    my ($fh, $type, $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
        $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
        $monthlet, $yeartime, $colour, $image, $position) = @_;

    # Write the base information to the file
    print $fh "$Yco $Xco \"$text1 $text2 $text3 $text4 $weekday $monthday $monthlet $yeartime\" ";


    # Determine the color based on the time difference
    if ($time_difference < $warning_length->{$type}) {
        print $fh "color=$ok_color";  # Status is OK
    } elsif ($time_difference < $warning_length->{"${type}error"}) {
        print $fh "color=$warn_color";  # Status is Warning
    } else {
        print $fh "color=$failed_color";  # Status is Failed
    }

    # Write additional properties
    print $fh " image=$image position=$position\n";
}


sub num_of_month {
    my ($month) = @_;
    my %months = (
        Jan => 0,  Feb => 1,  Mar => 2,  Apr => 3,  May => 4,  Jun => 5,
        Jul => 6,  Aug => 7,  Sep => 8,  Oct => 9,  Nov => 10, Dec => 11
    );
    return $months{$month};
}

# Helper to write a file header (called when creating a new file)
sub file_header {
    my ($openfile, $filehandle) = @_;

    # Check if the filehandle is valid before proceeding
    unless (defined $filehandle && fileno($filehandle)) {
        die "Filehandle is not valid or not open in Label::file_header";
    }

    # Get the current date and time
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $formatted_date = sprintf("%02d-%s-%04d %02d:%02d", $mday, $months[$mon], $year, $hour, $min);

    # Write the header to the file
    print $filehandle "# This is the header for $openfile\n";
    print $filehandle "# Original idea by Michael Dear\n";
    print $filehandle "# Revamped by Matt Coblentz October 2024\n";
    print $filehandle "# Updated $formatted_date\n";  # Add the formatted date and time
    print $filehandle "# \n";
}

1; # End of the module
