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
    unless (defined $labelsettings) {
        die "Error: \$labelsettings is not defined. Ensure Label settings are defined in the .ini file.";
    }
    
    my ($update_earth, $update_norad, $update_cloud, $update_hurricane, $update_volcano, $update_label) = @_;
    my @Yco_ords;       # Array for Y coordinates.
    my @Xco_ords;       # Array for X coordinates.
    my @text1;          # Arrays for various text fields.
    my @text2;
    my @text3;
    my @text4;
    my @weekday;
    my @monthday;
    my @monthlet;
    my @yeartime;
    my @colour;         # Array for label colors.
    my @image;          # Array for image settings.
    my @position;       # Array for positions.
    my $sec;            # Variables for time components.
    my $min;
    my $hour;
    my $year;
    my $mday;
    my $mon;
    my $wday;
    my $yday;
    my $isdst;
    my $thisday;        # Current weekday.
    my $thismonth;      # Current month.
    my $time_now;       # Current time as a timestamp.
    my $openfile;       # Name of the file being processed.
    my $labellocate;    # Location for the label.

    # Update flags to ensure they are set to 0 or 1.
    $update_earth = $update_earth >= 1 ? 1 : 0;
    $update_norad = $update_norad >= 1 ? 1 : 0;
    $update_cloud = $update_cloud >= 1 ? 1 : 0;
    $update_hurricane = $update_hurricane >= 1 ? 1 : ($update_hurricane == -1 ? 1 : 0);
    $update_volcano = $update_volcano >= 1 ? 1 : 0;

    # Debugging print for labelsettings
    print "\$update_earth is $update_earth\n";
    print "\$update_norad is $update_norad\n";
    print "\$update_cloud is $update_cloud\n";
    print "\$update_hurricane is $update_hurricane\n";
    print "\$update_volcano is $update_volcano\n";
    print "\$update_label is $update_label\n";

    # If $update_label is set, reset all other update flags to 0.
    if ($update_label >= 1) {
        $update_earth = $update_norad = $update_cloud = $update_hurricane = $update_volcano = 0;
    }

    # debug statement, setting labels to 1
    $update_earth = $update_norad = $update_cloud = $update_hurricane = $update_volcano = 1;


    my $counter = 0;  # Initialize counter for tracking entries.
    my $ok_color = $labelsettings->{'LabelColorOk'};       # OK label color.
    my $warn_color = $labelsettings->{'LabelColorWarn'};   # Warning label color.
    my $failed_color = $labelsettings->{'LabelColorError'};# Failed label color.

    # Open the label file for reading.
    print "\$label_file is $label_file\n";

    open(my $read_fh, '<', $label_file) or die "Cannot open $label_file for writing: $!";

    # Read the file line by line, splitting data into the respective arrays.
    while (<$read_fh>) {
        print "Entries read:\n";
        for my $i (0 .. $#text1) {
        print "$i: $text1[$i] - $text2[$i] - $text3[$i] - $text4[$i]\n";
        }

        (
            $Yco_ords[$counter], $Xco_ords[$counter], $text1[$counter], $text2[$counter], 
            $text3[$counter], $text4[$counter], $weekday[$counter], $monthday[$counter], 
            $monthlet[$counter], $yeartime[$counter], $colour[$counter], $image[$counter], 
            $position[$counter]
        ) = split(" ");
        $counter++;
    }
    
    # Close the label file after reading.
    close($read_fh) or warn "Could not close $label_file: $!";
    print "Label file successfully written to $label_file\n";

    # Define the %warning_length hash.
    my %warning_length = (
        quake          => ($labelsettings->{'LabelWarningQuake'} // 1) * 1,
        cloud          => ($labelsettings->{'LabelWarningCloud'} // 1) * 1,
        norad          => ($labelsettings->{'LabelWarningNorad'} // 1) * 1,
        hurricane      => ($labelsettings->{'LabelWarningStorm'} // 1) * 1,
        volcano        => ($labelsettings->{'LabelWarningVolcano'} // 1) * 1,
        quakeerror     => ($labelsettings->{'LabelWarningQuake'} // 1) * 2,
        clouderror     => ($labelsettings->{'LabelWarningCloud'} // 1) * 2,
        noraderror     => ($labelsettings->{'LabelWarningNorad'} // 1) * 2,
        hurricaneerror => ($labelsettings->{'LabelWarningStorm'} // 1) * 2,
        volcanoerror   => ($labelsettings->{'LabelWarningVolcano'} // 1) * 2,
    );

    # Open the label file for writing, with error handling.
    open(my $write_fh, '>', $label_file) or die "Cannot open $label_file: $!";
    
    # Set the open file name to 'UpdateLabel'.
    $openfile = 'UpdateLabel';

    # Pass the filehandle (MF) to file_header for writing the file header.
    file_header($openfile, $write_fh);

    my $recounter = 0;  # Initialize recounter.

    # Loop through each entry and process updates.
    while ($recounter != $counter) {
        if ($update_earth && $text1[$recounter] =~ /Earthquake/) {
            # Process Earthquake updates.
            process_update($write_fh, $update_earth, 'quake', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_earth = 0;  # Reset flag after update.
        } elsif ($update_norad && $text1[$recounter] =~ /NORAD/) {
            # Process NORAD updates.
            process_update($write_fh, $update_norad, 'norad', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_norad = 0;  # Reset flag after update.
        } elsif ($update_cloud && $text1[$recounter] =~ /Cloud/) {
            # Process Cloud updates.
            process_update($write_fh, $update_cloud, 'cloud', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_cloud = 0;  # Reset flag after update.
        } elsif ($update_hurricane && $text1[$recounter] =~ /Storm/) {
            # Process Hurricane updates.
            process_update($write_fh, $update_hurricane, 'hurricane', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_hurricane = 0;  # Reset flag after update.
        } elsif ($update_volcano && $text1[$recounter] =~ /Volcano/) {
            # Process Volcano updates.
            process_update($write_fh, $update_volcano, 'volcano', $ok_color, $warn_color, $failed_color, 
                           $Yco_ords[$recounter], $Xco_ords[$recounter], $text1[$recounter], 
                           $text2[$recounter], $text3[$recounter], $text4[$recounter], 
                           $weekday[$recounter], $monthday[$recounter], $monthlet[$recounter], 
                           $yeartime[$recounter], $colour[$recounter], $image[$recounter], 
                           $position[$recounter], \%warning_length, $wday);
            $update_volcano = 0;  # Reset flag after update.
        } elsif ($Yco_ords[$recounter] =~ /-\d\d/ && $text3[$recounter] =~ /Last/ && $text4[$recounter] =~ /Updated/) {
            # Process last update for certain entries.
            process_last_update($write_fh, \%warning_length, $ok_color, $warn_color, $failed_color, 
                                $time_now, $Yco_ords[$recounter], $Xco_ords[$recounter], 
                                $text1[$recounter], $text2[$recounter], $text3[$recounter], 
                                $text4[$recounter], $weekday[$recounter], $monthday[$recounter], 
                                $monthlet[$recounter], $yeartime[$recounter], $colour[$recounter], 
                                $image[$recounter], $position[$recounter]);
        }
        # Move to the next entry.
        $recounter++;
    }

    # Close the file after all updates are written.
    close($write_fh) or warn "Could not close $label_file: $!";
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

    # Use the filehandle directly
    print $filehandle "# This is the header for $openfile\n";
    print $filehandle "# Original idea by Michael Dear\n";
    print $filehandle "# Revamped by Matt Coblentz October 2024\n";
    print $filehandle "# Updated $formatted_date\n";  # Add the formatted date and time
    print $filehandle "# \n";
}


1; # End of the module
