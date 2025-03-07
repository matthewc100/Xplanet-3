package Globals;
use strict;
use warnings;
use Exporter 'import';
use Storable 'dclone';  # Avoiding issues with [MISC section settings]
use Time::Local;  # Required for convert_to_epoch


# Reference the global $DEBUG variable from the main script
use vars qw($DEBUG);

# Exported variables and functions for use in other modules
our $DEBUG = 0;  # Default debugging to off
our @EXPORT_OK = qw(
    $DEBUG
    collect_module_flags
    convert_to_epoch
    
    $settings
    %modules
    $xplanet_dir
    $settings_ini_file
    update_directories
    initialize_xplanet_dir
    debug_print_modules
    $xplanet_markers_dir
    $xplanet_arcs_dir
    $xplanet_images_dir
    $xplanet_config_dir
    $xplanet_satellites_dir

    $quakesettings 
    @quakedata
    $Earthquake
    $quake_marker_file

    set_pversion

    $noradsettings
    $iss_file
    $isstle_file
 
    get_webpage

    $volcano_marker_file
    $volcanosettings 

    $stormsettings
    $hurricane_arc_file
    $hurricane_marker_file

    $labelsettings
    $label_file

    $cloudsettings 

    $eclipse_marker_file
    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_arc_file
    $eclipse_data_file
    $eclipse_location
    $eclipse_marker_file
    @eclipsedata
    @eclipsetrack
    @eclipserefined
);

# Globals
our (
    $settings,            # Stores general application settings
    %modules,             # New hash for dynamically storing module settings
    $xplanet_dir,         # Main directory for xplanet
    $xplanet_markers_dir, # Directory for marker files
    $xplanet_arcs_dir,    # Directory for arc files
    $xplanet_satellites_dir, # Directory for satellite files
    $xplanet_images_dir,  # Directory for image files
    $xplanet_config_dir,  # Directory for configuration files
    $settings_ini_file,   # Path to the .ini file

    # Legacy variables for backward compatibility
    $noradsettings,
    $iss_file,
    $isstle_file,
    $cloudsettings,
    $quake_marker_file,
    @quakedata,
    $quake_location,
    $quakesettings, 
    $Earthquake,
    $volcano_marker_file,
    $volcanosettings,
    $stormsettings,
    $hurricane_arc_file,
    $hurricane_marker_file,
    $label_file,
    $labelsettings,
    $eclipse_arc_file,
    $eclipse_data_file,
    $eclipse_location,
    $eclipse_marker_file,
    @eclipsedata,
    @eclipsetrack,
    @eclipserefined
);

#################################################
#  CONFIGURATION SECTION                        #
#################################################

# Initializes $xplanet_dir and ensures it is valid
# If $xplanet_dir is not set via the environment, uses a hardcoded default
sub initialize_xplanet_dir {
    $xplanet_dir = $ENV{'XPLANET_DIR'} || "C:\\Users\\mcoblent\\onedrive\\xplanet\\xplanet-1.3.0\\xplanet-3";

    # Validate the directory and ensure it exists
    -d $xplanet_dir or die("Invalid xplanet directory: $xplanet_dir\n");

    # Update dependent directories based on $xplanet_dir
    update_directories();
}

# Reads the configuration file and loads settings into globals
# This function expects $xplanet_dir to already be initialized
sub get_directory_settings {
    # Path to the configuration file
    $settings_ini_file = "$xplanet_dir\\config\\totalmarker.ini";

    # Open the configuration file for reading
    open my $fh, '<', $settings_ini_file or die "Cannot open $settings_ini_file: $!";

    my $current_section = '';  # Tracks the current section in the .ini file
    my %current_settings;      # Temporary storage for settings in the current section

    while (<$fh>) {
        chomp;  # Remove newline characters

        # Skip empty lines and comments
        next if /^\s*$/ || /^\s*#/;

        # Identify section headers (e.g., [MISC], [LABELS])
        if (/^\[(.+)\]$/) {
            # Process the previous section before moving to the new one
            if ($current_section) {
                if ($current_section eq 'misc') {
                    # Store [MISC] settings in $settings hash
                    foreach my $key (keys %current_settings) {
                        $settings->{lc($key)} = $current_settings{$key};
                    }
                } else {
                    # Register non-MISC sections as modules
                    register_module_settings($current_section, \%current_settings);
                }
            }

            # Start a new section
            $current_section = lc($1);  # Normalize the section name to lowercase
            %current_settings = ();    # Clear temporary storage for the new section
            next;
        }

        # Parse key-value pairs within a section
        my ($key, $value) = split('=', $_, 2);
        $key   //= '';  # Default to empty string if undefined
        $value //= '';  # Default to empty string if undefined
        $current_settings{$key} = $value;
    }

    # Handle the last section
    if ($current_section) {
        if ($current_section eq 'misc') {
            foreach my $key (keys %current_settings) {
                $settings->{lc($key)} = $current_settings{$key};
            }
        } else {
            register_module_settings($current_section, \%current_settings);
        }
    }

    close $fh;  # Close the configuration file

    # Debugging: Verify the $settings hash
    print "Globals line 180 - MISC Settings:\n" if $DEBUG;
    foreach my $key (keys %{$settings}) {
        print "  $key => $settings->{$key}\n" if $DEBUG;
    }
    # Debugging: Print registered modules before returning control
}


# Registers settings for a given module
# This function ensures both legacy global variables and the dynamic %modules hash are populated
sub register_module_settings {
    my ($module_name, $settings_hash) = @_;

    # Debug: Print the module being registered
    print "Globals line 194 - debugging \n" if $DEBUG;

    # Convert module name to lowercase for consistent lookups
    my $normalized_module = lc($module_name);
        print "Registering module: normalized_module\n" if $DEBUG;
        
    # Convert all keys in the module settings to lowercase
    my %normalized_settings;
    foreach my $key (keys %{$settings_hash}) {
        my $normalized_key = lc($key);
        $normalized_settings{$normalized_key} = $settings_hash->{$key};
        print "  Normalized Key: $normalized_key => $settings_hash->{$key}\n" if $DEBUG;
    }

    foreach my $key (keys %{$settings_hash}) {
        print "  $key => $settings_hash->{$key}\n" if $DEBUG;
    }

    my $legacy_var_name = lc($module_name) . 'settings';  # Convert the module name to a legacy variable name

    # Populate the legacy global variable (e.g., $stormsettings) for compatibility
    no strict 'refs';  # Temporarily disable strict references
    ${'Globals::' . $legacy_var_name} = dclone($settings_hash);  # Use deep copy

    # Store a deep copy in the dynamic %modules hash
    $modules{$module_name} = dclone($settings_hash);  # Use deep copy
}

# Updates directory paths based on the root directory ($xplanet_dir)
sub update_directories {
    $xplanet_markers_dir    = "$xplanet_dir\\markers";       # Directory for marker files
    $xplanet_arcs_dir       = "$xplanet_dir\\arcs";          # Directory for arc files
    $xplanet_satellites_dir = "$xplanet_dir\\satellites";    # Directory for satellite files
    $xplanet_images_dir     = "$xplanet_dir\\images";        # Directory for image files
    $xplanet_config_dir     = "$xplanet_dir\\config";        # Directory for configuration files

    # Set paths for specific files
    $quake_marker_file      = "$xplanet_markers_dir\\quake";
    $volcano_marker_file    = "$xplanet_markers_dir\\volcano";
    $hurricane_marker_file  = "$xplanet_markers_dir\\storm";
    $hurricane_arc_file     = "$xplanet_arcs_dir\\storm";
    $label_file             = "$xplanet_markers_dir\\updatelabel";
    $eclipse_marker_file    = "$xplanet_markers_dir\\eclipse";
    $eclipse_arc_file       = "$xplanet_arcs_dir\\eclipse";
    $eclipse_data_file      = "$xplanet_config_dir\\totalmarker.dat";
    $iss_file               = "$xplanet_satellites_dir\\tm";
    $isstle_file            = "$xplanet_satellites_dir\\tm.tle";
}

#################################################
#  END CONFIGURATION SECTION                    #
#################################################

# General application settings
$settings = {
    'XplanetVersion' => '1.2.3es',  # Version number of the application
    'pversion'       => undef,      # Placeholder for Perl version
};

# Setter function for $pversion
sub set_pversion {
    my ($value) = @_;
    $settings->{'pversion'} = $value;
}

# Fetches a webpage using LWP::UserAgent
sub get_webpage {
    my ($url) = @_;
    use LWP::UserAgent;

    # Create an LWP::UserAgent instance
    my $ua = LWP::UserAgent->new;
    $ua->timeout(15);  # Set a timeout for the request
    $ua->agent('Mozilla/5.0 (compatible; xPlanetBot/1.0)');  # Set a user-agent string

    # Send a GET request to the specified URL
    my $response = $ua->get($url);

    # Return the content if the request is successful, otherwise return 'FAILED'
    return $response->is_success ? $response->decoded_content : 'FAILED';
}

sub convert_to_epoch {
    my ($timestamp) = @_;

    if ($timestamp =~ /(\d{2})-(\w{3})-(\d{4}) (\d{2}):(\d{2})/) {
        my ($day, $month_str, $year, $hour, $minute) = ($1, $2, $3, $4, $5);
        
        my %months = (
            Jan => 0,  Feb => 1,  Mar => 2,  Apr => 3,  May => 4,  Jun => 5,
            Jul => 6,  Aug => 7,  Sep => 8,  Oct => 9,  Nov => 10, Dec => 11
        );

        my $month = $months{$month_str};
        return timelocal(0, $minute, $hour, $day, $month, $year - 1900);
    }

    return 0; # Return 0 if invalid timestamp
}


sub collect_module_flags {
    my @flags;  # Array to store the normalized on/off flags for all modules

    # Loop through all modules in %Globals::modules
    foreach my $module (sort keys %Globals::modules) {
        # Debugging: Print the module being processed
        print "Processing module: $module\n" if $DEBUG;

        # Check if the module contains any key that matches /onoff$/i
        my ($onoff_key) = grep { /onoff$/i } keys %{ $Globals::modules{$module} };

        if ($onoff_key) {
            # Normalize the value: "On" => 1, "Off" => 0, undefined => 0
            my $onoff_value = $Globals::modules{$module}{$onoff_key} // 0;
            $onoff_value = ($onoff_value =~ /^(1|On)$/i) ? 1 : 0;

            # Debugging: Print the normalized onoff value
            print "  Found onoff key ($onoff_key): $onoff_value\n" if $DEBUG;

            # Push the normalized value to the flags array
            push @flags, $onoff_value;
        } else {
            # Debugging: Module does not have an onoff key
            print "  No onoff key for module: $module\n" if $DEBUG;
        }
    }

    # Debugging: Print the final collected flags
    print "Final collected module flags: " . join(", ", @flags) . "\n" if $DEBUG;

    # Return the array of normalized on/off flags
    return @flags;
}

# Debug utility to print all registered modules and their settings
# This function is useful for troubleshooting and verifying module initialization
# Debug utility to print all registered modules and their settings
# This function is useful for troubleshooting and verifying module initialization
sub debug_print_modules {
    print "\n========== Registered Modules and Settings ==========\n";

    # Iterate over each module in %modules
    foreach my $module (keys %modules) {
        print "Module: $module\n";

        # Ensure the value is a hash reference
        if (ref($modules{$module}) eq 'HASH') {
            # Print each key-value pair within the module
            foreach my $key (keys %{$modules{$module}}) {
                print "  $key => $modules{$module}{$key}\n";
            }
        } else {
            # Warn if the value is not a hash reference
            print "  [Warning] Invalid data structure for module: $module\n";
        }

        print "\n";  # Add spacing between modules for readability
    }

    print "=====================================================\n";
}

1;  # End of module
