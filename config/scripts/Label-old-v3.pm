package Label;
use strict;
use warnings;
use Data::Dumper;
use Time::Local;  # Load the Time::Local module

use Globals qw(
    $DEBUG 
    $label_file 
    $labelsettings
);  

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
    print "Label line 31 - Debug: \$DEBUG is " . ($DEBUG ? "enabled" : "disabled") . "\n";

    my ($active_modules_ref) = @_;

    # Skip label generation if labelsdisplay is disabled
    my $labels_display = $Globals::modules{'labels'}{'labelsonoff'} // 1;  # Default to 1 (enabled)
    return unless $labels_display;

    print "Label line 39 - Debug: Labels display is " . ($labels_display ? "enabled" : "disabled") . "\n" if $DEBUG;

    # Debug: Check that active_modules_ref is a hash reference
    unless (ref $active_modules_ref eq 'HASH') {
        print "Label::WriteoutLabel - Received invalid active_modules_ref: " . (ref $active_modules_ref || 'undefined') . "\n" if $DEBUG;
        die "Error: active_modules_ref is not a HASH reference.";
    }

    # Debugging: Print the contents of active_modules_ref
    print "Label line 48 - Debug: active_modules_ref contents:\n" if $DEBUG;
    foreach my $module (keys %$active_modules_ref) {
        print "  $module => $active_modules_ref->{$module}\n" if $DEBUG;
    }

    # Dynamically map module names to update flags based on %Globals::modules{'labels'}
    my %types_to_check;
    foreach my $key (keys %{$Globals::modules{'labels'}}) {
        next unless $key =~ /\.position$/;  # Only check .position keys 

        my $module = $key;
        $module =~ s/\.position$//;  # Remove .position suffix to get module name   

        print "Label::WriteoutLabel line 61 - Checking $key (Normalized: $module)\n" if $DEBUG; 

        # Store module status (active/inactive)
        $types_to_check{$module} = ($active_modules_ref->{$module} // 0) ? 1 : 0;   

        # Debug: Confirm storage
        print "Label::WriteoutLabel line 67 - Adding $module to types_to_check with flag: $types_to_check{$module}\n" if $DEBUG;
    }


    # Fallback for modules missing .position keys
    foreach my $module (keys %types_to_check) {
        unless (exists $Globals::modules{'labels'}{"${module}.position"}) {
            print "Label::WriteoutLabel line 68 - Missing position for $module. Using default.\n" if $DEBUG;
            $Globals::modules{'labels'}{"${module}.position"} = '-100,-100';
        }
    }

    # Retrieve positions and colors
    my %type_positions;
    foreach my $module (keys %types_to_check) {
        my $position_key = "${module}.position";  # Keep original capitalization    

        if (exists $Globals::modules{'labels'}{$position_key}) {
            my $position = $Globals::modules{'labels'}{$position_key};  

            if (defined $position && $position ne '') {
                my ($x, $y) = split(',', $position);
                $type_positions{$module} = [$x, $y];    

                print "Label::WriteoutLabel - Position for $module: ($x, $y)\n" if $DEBUG;
            } else {
                print "Label::WriteoutLabel - Warning: Empty position for $module! Using default (-100,-100).\n" if $DEBUG;
                $type_positions{$module} = [-100, -100];  # Assign default
            }
        } else {
            print "Label::WriteoutLabel - Warning: No position found for $module! Using default (-100,-100).\n" if $DEBUG;
            $type_positions{$module} = [-100, -100];  # Assign default
        }
    }

    # Make sure to declare %type_colors **AFTER** %type_positions
    my %type_colors = (
        "OK"    => $Globals::modules{'labels'}{'Label.Color.Ok'}    // 'Green',
        "Warn"  => $Globals::modules{'labels'}{'Label.Color.Warn'}  // 'Yellow',
        "Error" => $Globals::modules{'labels'}{'Label.Color.Error'} // 'Red',
    );


    # Debug: Print retrieved data
    print "Label line 111 - Debug: types_to_check:\n" . Dumper(\%types_to_check) if $DEBUG;
    print "Label line 112 - Debug: type_positions:\n" . Dumper(\%type_positions) if $DEBUG;
    print "Label line 90113 - Debug: type_colors:\n" . Dumper(\%type_colors) if $DEBUG;

    # Proceed with existing logic to process and write out labels
}



# Subroutine to generate an "inactive" label message
sub generate_inactive_message {
    my ($type, $type_positions, $type_colors, $formatted_time) = @_;
    my ($Yco, $Xco) = @{$type_positions->{$type}};
    my $color = $type_colors->{'Warn'};  # Use the warning color for inactive modules

    return "$Yco $Xco \"$type module is inactive $formatted_time\" color=$color image=none position=pixel";
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
