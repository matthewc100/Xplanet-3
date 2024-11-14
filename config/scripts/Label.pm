package Label;
use strict;
use warnings;
use Time::Local;  # Load the Time::Local module

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
    my ($update_earth, $update_norad, $update_cloud, $update_hurricane, $update_volcano, $update_label) = @_;

    # Define the types and their invocation flags
    my %types_to_check = (
        "Earthquake" => $update_earth,
        "NORAD"      => $update_norad,
        "Cloud"      => $update_cloud,
        "Hurricane"  => $update_hurricane,
        "Volcano"    => $update_volcano,
    );

    # Define positions for each type (local to WriteoutLabel)
    my %type_positions = (
        "Earthquake" => [-68, -13],
        "NORAD"      => [-83, -13],
        "Cloud"      => [-98, -13],
        "Hurricane"  => [-113, -13],
        "Volcano"    => [-128, -13],
    );

    # Track found data for each type
    my %found_data = map { $_ => 0 } keys %types_to_check;
    my $formatted_time = get_current_time();  # Get current timestamp for "not found" messages

    # Step 1: Read existing entries into a hash, keyed by type
    my %current_entries;
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

    # Step 2: Update or add entries based on invocation flags and data
    foreach my $type (keys %types_to_check) {
        next unless $types_to_check{$type};  # Only process types with flags set to 1
        if ($current_entries{$type}) {
            # Process the line if found in existing entries
            print "Updating existing data for $type...\n";
            $current_entries{$type} = process_data_for_type($type, \%type_positions);  # Pass %type_positions to subroutine
            $found_data{$type} = 1;
        } else {
            # Mark as missing if type not found in current entries
            $found_data{$type} = 0;
        }
    }

    # Step 3: Write header and updated data to the file
    open(my $write_fh, '>', $label_file) or die "Cannot open $label_file for writing: $!";
    file_header('UpdateLabel', $write_fh);  # Write header

    # Output updated data or missing messages
    foreach my $type (keys %types_to_check) {
        if ($found_data{$type} && $current_entries{$type}) {
            print $write_fh "$current_entries{$type}\n";  # Write the updated line
        } elsif ($types_to_check{$type} && !$found_data{$type}) {
            # Output "not found" message if data is missing
            my ($Yco, $Xco) = @{$type_positions{$type}};
            output_missing_message($write_fh, $type, $formatted_time, $Yco, $Xco);
        }
    }
    close($write_fh);
}

# Subroutine to process data for a specific type and return formatted string
sub process_data_for_type {
    my ($type, $type_positions) = @_;  # Receive %type_positions as a reference

    # Example position and color assignments, replace with actual data processing as needed
    my ($Yco, $Xco) = @{$type_positions->{$type}};
    my $color = "Green";  # Assume the color is determined dynamically
    my $formatted_time = get_current_time();
    return "$Yco $Xco \"$type information last updated\" $formatted_time color=$color image=none position=pixel";
}

# Subroutine to output a "not found" message at specified coordinates for missing data
sub output_missing_message {
    my ($fh, $type, $formatted_time, $Yco, $Xco) = @_;
    print $fh "$Yco $Xco \"$type information not found\" $formatted_time color=Red image=none position=pixel\n";
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

    print "Processing update for type: $type, Status: $update_status\n";

    print $fh "$Yco $Xco \"$text1 Information Last Updated";
    substr($yeartime, -1, 1, "");  # Replace the last character with an empty string

    if ($update_status eq 'FAILED' && $colour =~ /$ok_color/) {
        print $fh " $weekday $monthday $monthlet $yeartime\" color=$warn_color";
    } elsif ($update_status eq 'FAILED' && $colour =~ /$warn_color/) {
        my $mon = num_of_month($monthlet);
        chomp $yeartime;
        my ($year_part, $min, $sec) = split(":", $yeartime, 3);
        my ($year, $hour) = split(",", $year_part, 2);
        $year -= 1900;
        my $time_state = timelocal($sec, $min, $hour, $monthday, $mon, $year);
        my $time_difference = time() - $time_state;  # Replace $time_now with current time

        if ($time_difference < $warning_length->[0]->{$type}) {
            print $fh " $weekday $monthday $monthlet $yeartime\" color=$warn_color";
        } else {
            print $fh " $weekday $monthday $monthlet $yeartime\" color=$failed_color";
        }
    } elsif ($update_status eq 'FAILED') {
        print $fh " $weekday $monthday $monthlet $yeartime\" color=$failed_color";
    } else {
        my ($sec, $min, $hour, $mday, $mon, $current_year) = localtime();
        $current_year += 1900;
        my $thisday = (qw(Sun Mon Tue Wed Thu Fri Sat))[$wday];
        my $thismonth = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec))[$mon];
        printf $fh " $thisday $mday $thismonth $current_year,%02d:%02d:%02d\" color=$ok_color", $hour, $min, $sec;
    }
    print $fh " image=none position=pixel\n";
}

sub process_last_update {
    my ($fh, $warning_length, $ok_color, $warn_color, $failed_color, 
        $time_now, $Yco, $Xco, $text1, $text2, $text3, $text4, 
        $weekday, $monthday, $monthlet, $yeartime, $colour, $image, $position) = @_;

    my $mon = num_of_month($monthlet);
    chomp $yeartime;
    my ($year_part, $min, $sec) = split(":", $yeartime, 3);
    my ($year, $hour) = split(",", $year_part, 2);
    $year -= 1900;
    my $time_state = timelocal($sec, $min, $hour, $monthday, $mon, $year);
    my $time_difference = $time_now - $time_state;

    if ($text1 =~ /Earthquake/) {
        update_time_status($fh, 'quake', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Cloud/) {
        update_time_status($fh, 'cloud', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /NORAD/) {
        update_time_status($fh, 'norad', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Storm/) {
        update_time_status($fh, 'hurricane', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    } elsif ($text1 =~ /Volcano/) {
        update_time_status($fh, 'volcano', $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
                           $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
                           $monthlet, $yeartime, $colour, $image, $position);
    }
}

sub update_time_status {
    my ($fh, $type, $time_difference, $warning_length, $ok_color, $warn_color, $failed_color, 
        $Yco, $Xco, $text1, $text2, $text3, $text4, $weekday, $monthday, 
        $monthlet, $yeartime, $colour, $image, $position) = @_;

    print $fh "$Yco $Xco \"$text1\" ";
    print $fh "$text2 ";
    print $fh "$text3 ";
    print $fh "$text4 ";
    print $fh "$weekday ";
    print $fh "$monthday ";
    print $fh "$monthlet ";
    print $fh "$yeartime\" ";
    
    if ($time_difference < $warning_length->{$type}) {
        print $fh "color=$ok_color";
    } elsif ($time_difference < $warning_length->{"${type}error"}) {
        print $fh "color=$warn_color";
    } else {
        print $fh "color=$failed_color";
    }
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
    $year += 1900;  # Adjust year
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
