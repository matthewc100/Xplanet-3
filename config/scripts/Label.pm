package Label;
use strict;
use warnings;
use Data::Dumper;
use Time::Local;
use File::stat;

use Globals qw(
    $DEBUG 
    $label_file 
    $labelsettings
    convert_to_epoch
);

sub WriteoutLabel {
    my ($active_modules_ref) = @_;

    # Skip label generation if labelsdisplay is disabled
    my $labels_display = $Globals::modules{'labels'}{'labelsonoff'} // 1;
    return unless $labels_display;

    print "Label line 39 - Debug: Labels display is " . ($labels_display ? "enabled" : "disabled") . "\n" if $DEBUG;

    # Ensure active_modules_ref is a valid hash reference
    unless (ref $active_modules_ref eq 'HASH') {
        print STDERR "Label::WriteoutLabel - Received invalid active_modules_ref: " . (ref $active_modules_ref || 'undefined') . "\n";
        die "Error: active_modules_ref is not a HASH reference.";
    }

    # 1️⃣ **📌 FILE INTEGRITY CHECK: Ensure updatelabel exists and is valid**
    my $current_time = time();
    if (!-e $label_file) {
        print STDERR "Warning: updatelabel file is missing. Regenerating...\n";
    }
    else {
        my $file_stat = stat($label_file);
        if ($file_stat) {
            my $file_mtime = $file_stat->mtime;
            my $file_timestamp = scalar localtime($file_mtime);

            # Convert file timestamp to epoch for comparison
            my $epoch_timestamp = convert_to_epoch($file_timestamp);

            if ($epoch_timestamp > $current_time) {
                print STDERR "Warning: updatelabel file has a future timestamp! Regenerating...\n";
            } elsif ($current_time - $epoch_timestamp > 86400) {
                print STDERR "Warning: updatelabel file is outdated (Last updated: $file_timestamp). Regenerating...\n";
            }
        } else {
            print STDERR "Warning: Failed to retrieve updatelabel file timestamp. Regenerating...\n";
        }
    }

    # 2️⃣ **Dynamically map module names to update flags based on %Globals::modules{'labels'}**
    my %types_to_check;
    foreach my $key (keys %{$Globals::modules{'labels'}}) {
        next unless $key =~ /\.position$/;

        my $module = $key;
        $module =~ s/\.position$//;

        print "Label::WriteoutLabel line 61 - Checking $key (Normalized: $module)\n" if $DEBUG;

        # Store module status (active/inactive)
        $types_to_check{$module} = ($active_modules_ref->{$module} // 0) ? 1 : 0;

        # Debug: Confirm storage
        print "Label::WriteoutLabel line 67 - Adding $module to types_to_check with flag: $types_to_check{$module}\n" if $DEBUG;
    }

    # 3️⃣ **Ensure positions exist or fallback to defaults**
    my %type_positions;
    foreach my $module (keys %types_to_check) {
        my $position_key = "${module}.position";

        if (exists $Globals::modules{'labels'}{$position_key}) {
            my $position = $Globals::modules{'labels'}{$position_key};

            if (defined $position && $position ne '') {
                my ($x, $y) = split(',', $position);
                $type_positions{$module} = [$x, $y];

                print "Label::WriteoutLabel - Position for $module: ($x, $y)\n" if $DEBUG;
            } else {
                print STDERR "Warning: Empty position for $module! Using default (-100,-100).\n";
                $type_positions{$module} = [-100, -100];
            }
        } else {
            print STDERR "Warning: No position found for $module! Using default (-100,-100).\n";
            $type_positions{$module} = [-100, -100];
        }
    }

    # **Declare `%type_colors` properly**
    my %type_colors = (
        "OK"    => $Globals::modules{'labels'}{'Label.Color.Ok'}    // 'Green',
        "Warn"  => $Globals::modules{'labels'}{'Label.Color.Warn'}  // 'Yellow',
        "Error" => $Globals::modules{'labels'}{'Label.Color.Error'} // 'Red',
    );

    # Debug: Print retrieved data
    print "Label line 111 - Debug: types_to_check:\n" . Dumper(\%types_to_check) if $DEBUG;
    print "Label line 112 - Debug: type_positions:\n" . Dumper(\%type_positions) if $DEBUG;
    print "Label line 113 - Debug: type_colors:\n" . Dumper(\%type_colors) if $DEBUG;

    ### 🔥🔥🔥 Step 4: Write the marker file 🔥🔥🔥 ###
    open(my $write_fh, '>', $label_file) or die "Cannot open $label_file for writing: $!";
    file_header('UpdateLabel', $write_fh);

    # Debugging: Confirm writing to file
    print "Label::WriteoutLabel - Debug: Writing data to $label_file...\n" if $DEBUG;

    foreach my $module (keys %type_positions) {
        my ($x, $y) = @{$type_positions{$module}};
        my $color = $type_colors{'OK'};

        # **📌 NEW: Add current date & time to label output**
        my $timestamp = get_current_time();
        my $line = "$x $y \"$module information last updated-- $timestamp\" color=$color image=none position=pixel\n";

        # Debug: Print what will be written
        print "Label::WriteoutLabel - Writing line: $line" if $DEBUG;

        print $write_fh $line;
    }

    close($write_fh);
    print "Label::WriteoutLabel - Finished writing to $label_file.\n" if $DEBUG;
}

# 📌 **Helper: Get current timestamp**
sub get_current_time {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    $mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon];
    return sprintf("%02d-%s-%04d %02d:%02d", $mday, $mon, $year, $hour, $min);
}

# 📌 **File header function**
sub file_header {
    my ($openfile, $filehandle) = @_;

    unless (defined $filehandle && fileno($filehandle)) {
        die "Filehandle is not valid or not open in Label::file_header";
    }

    my $timestamp = get_current_time();
    print $filehandle "# This is the header for $openfile\n";
    print $filehandle "# Original idea by Michael Dear\n";
    print $filehandle "# Revamped by Matt Coblentz October 2024\n";
    print $filehandle "# Updated $timestamp\n";
    print $filehandle "# \n";
}

1; # End of module
