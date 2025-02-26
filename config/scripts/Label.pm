package Label;
use strict;
use warnings;
use Data::Dumper;
use Time::Local;

use Globals qw(
    $DEBUG 
    $label_file 
    $labelsettings
);  

sub WriteoutLabel {
    print "Label line 31 - Debug: \$DEBUG is " . ($DEBUG ? "enabled" : "disabled") . "\n";

    my ($active_modules_ref) = @_;

    # Skip label generation if labelsdisplay is disabled
    my $labels_display = $Globals::modules{'labels'}{'labelsonoff'} // 1;  
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
        next unless $key =~ /\.position$/;  

        my $module = $key;
        $module =~ s/\.position$//;  

        print "Label::WriteoutLabel line 61 - Checking $key (Normalized: $module)\n" if $DEBUG; 

        # Store module status (active/inactive)
        $types_to_check{$module} = ($active_modules_ref->{$module} // 0) ? 1 : 0;   

        # Debug: Confirm storage
        print "Label::WriteoutLabel line 67 - Adding $module to types_to_check with flag: $types_to_check{$module}\n" if $DEBUG;
    }

    # Fallback for modules missing .position keys
    foreach my $module (keys %types_to_check) {
        unless (exists $Globals::modules{'labels'}{"${module}.position"}) {
            print "Label::WriteoutLabel - Warning: No position found for $module! Using default (-100,-100).\n" if $DEBUG;
            $Globals::modules{'labels'}{"${module}.position"} = '-100,-100';
        }
    }

    # Retrieve positions
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
                print "Label::WriteoutLabel - Warning: Empty position for $module! Using default (-100,-100).\n" if $DEBUG;
                $type_positions{$module} = [-100, -100];  
            }
        } else {
            print "Label::WriteoutLabel - Warning: No position found for $module! Using default (-100,-100).\n" if $DEBUG;
            $type_positions{$module} = [-100, -100];  
        }
    }

    # **💡 FIX: Declare `%type_colors` properly**
    my %type_colors = (
        "OK"    => $Globals::modules{'labels'}{'Label.Color.Ok'}    // 'Green',
        "Warn"  => $Globals::modules{'labels'}{'Label.Color.Warn'}  // 'Yellow',
        "Error" => $Globals::modules{'labels'}{'Label.Color.Error'} // 'Red',
    );

    # Debug: Print retrieved data
    print "Label line 111 - Debug: types_to_check:\n" . Dumper(\%types_to_check) if $DEBUG;
    print "Label line 112 - Debug: type_positions:\n" . Dumper(\%type_positions) if $DEBUG;
    print "Label line 113 - Debug: type_colors:\n" . Dumper(\%type_colors) if $DEBUG;

    ### 🔥🔥🔥 Step 3: Write the marker file 🔥🔥🔥 ###
    open(my $write_fh, '>', $label_file) or die "Cannot open $label_file for writing: $!";
    file_header('UpdateLabel', $write_fh);

    # Debugging: Confirm writing to file
    print "Label::WriteoutLabel - Debug: Writing data to $label_file...\n" if $DEBUG;

    foreach my $module (keys %type_positions) {
        my ($x, $y) = @{$type_positions{$module}};
        my $color = $type_colors{'OK'};  
        my $line = "$x $y \"$module information updated\" color=$color image=none position=pixel\n";

        # Debug: Print what will be written
        print "Label::WriteoutLabel - Writing line: $line" if $DEBUG;

        print $write_fh $line;  
    }

    close($write_fh);
    print "Label::WriteoutLabel - Finished writing to $label_file.\n" if $DEBUG;
}

# File header function
sub file_header {
    my ($openfile, $filehandle) = @_;

    unless (defined $filehandle && fileno($filehandle)) {
        die "Filehandle is not valid or not open in Label::file_header";
    }

    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $formatted_date = sprintf("%02d-%s-%04d %02d:%02d", $mday, $months[$mon], $year, $hour, $min);

    print $filehandle "# This is the header for $openfile\n";
    print $filehandle "# Original idea by Michael Dear\n";
    print $filehandle "# Revamped by Matt Coblentz October 2024\n";
    print $filehandle "# Updated $formatted_date\n";  
    print $filehandle "# \n";
}

1;
